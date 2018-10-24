################################################################
# Infrastructure variables to be read from variables.tfvars    #
################################################################

variable "region" {}
variable "shared_credentials_file" {}
variable "profile" {}
variable "sfn_triggerer_lambda_function" {}
variable "rds_pass" {}

data "aws_availability_zones" "all" {}

################################################################

################################################################
# Defining the provider (AWS in this case)                     #
################################################################

provider "aws" {
  region="${var.region}"
  shared_credentials_file="${var.shared_credentials_file}"
  profile="${var.profile}"
}

################################################################

################################################################
# Defining a vpc                                               #
################################################################

resource "aws_vpc" "terraform" {

  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining a security group                                    #
################################################################

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.terraform.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining a subnets                                           #
################################################################

resource "aws_subnet" "main" {
    vpc_id     = "${aws_vpc.terraform.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${data.aws_availability_zones.all.names[0]}"

    tags {
      name = "frbhackathon2018"
    }
}

resource "aws_subnet" "secondary" {
    vpc_id     = "${aws_vpc.terraform.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "${data.aws_availability_zones.all.names[1]}"
    tags {
        name = "frbhackathon2018"
    }
}

################################################################

################################################################
# Defining an internet gateway                                 #
################################################################

resource "aws_internet_gateway" "gw" {
     vpc_id = "${aws_vpc.terraform.id}"

     tags {
        name = "frbhackathon2018"
     }
}

################################################################

resource "aws_route_table" "public-rt" {
    vpc_id = "${aws_vpc.terraform.id}"
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
    name = "frbhackathon2018"
  }
}

resource "aws_route_table_association" "public-rt-1" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_route_table_association" "public-rt-2" {
    subnet_id = "${aws_subnet.secondary.id}"
    route_table_id = "${aws_route_table.public-rt.id}"
}

################################################################
# Defining the lambda role                                     #
################################################################

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

################################################################

################################################################
# Defining a lambda role policy                                #
################################################################

resource "aws_iam_policy" "lambda_role_policy" {
  name        = "lambda_role_policy"
  description = "Defines lambda role policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "ec2:CreateNetworkInterface",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

################################################################

################################################################
# Attaching the lambda role policy to lambda role              #
################################################################

resource "aws_iam_role_policy_attachment" "attach_to_lambda_role" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_role_policy.arn}"
}

################################################################

################################################################
# Defining the AWS lambdas                                     #
################################################################

resource "aws_lambda_function" "sfn_triggerer" {
  filename         = "${var.sfn_triggerer_lambda_function}"
  function_name    = "sfn_triggerer_tf"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "sfn_triggerer_tf.lambda_handler"
  runtime          = "python3.6"

  vpc_config {
          subnet_ids = ["${aws_subnet.main.id}"]
          security_group_ids = ["${aws_security_group.allow_all.id}"]
  }

  environment {
    variables = {
      foo = "bar"
    }
  }
  tags {
    name = "frbhackathon2018"
  }
}

################################################################
# Defining the s3 bucket                                       #
################################################################

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "frbhackathon2018tf"
  acl    = "private"
  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining a prefix inside the s3 buckets3 prefix              #
################################################################

resource "aws_s3_bucket_object" "source" {
  bucket = "${aws_s3_bucket.s3_bucket.id}"
  acl    = "private"
  key    = "source/"
  source = "nul"
}

################################################################

################################################################
# Defining the lambda permissions                              #
################################################################

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sfn_triggerer.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.s3_bucket.arn}"
}

################################################################

################################################################
# setting s3 bucket notification                               #
################################################################

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.s3_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.sfn_triggerer.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
  }
}

################################################################

################################################################
# creating subnet_group                                        #
################################################################

resource "aws_db_subnet_group" "subnet_group" {
    name        = "subnet_group"
    description = "subnet group for RDS"
    subnet_ids  = ["${aws_subnet.main.id}","${aws_subnet.secondary.id}"]
}

################################################################
# adding a RDS instance                                        #
################################################################

resource "aws_db_instance" "frbhackathon2018tf" {
    allocated_storage    = 10
    identifier           = "frbhackathon2018tf"
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7.23"
    instance_class       = "db.t2.micro"
    name                 = "frbhackathon2018tf"
    username             = "root"
    password             = "${var.rds_pass}"
    parameter_group_name = "default.mysql5.7"
    publicly_accessible  = true
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    db_subnet_group_name   = "${aws_db_subnet_group.subnet_group.id}"
    skip_final_snapshot = true
    tags {
        name = "frbhackathon2018"
    }
}

################################################################