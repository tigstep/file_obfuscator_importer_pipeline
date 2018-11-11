################################################################
# Infrastructure variables to be read from variables.tfvars    #
################################################################

variable "region" {}
variable "shared_credentials_file" {}
variable "profile" {}
variable "sfn_triggerer_lambda_function" {}
variable "data_obfuscator_lambda_function" {}
variable "rds_inserter_lambda_function" {}
variable "notifier_lambda_function" {}
variable "rds_pass" {}
variable "ssh_key" {}

data "aws_availability_zones" "all" {}

################################################################

################################################################
# Defining the provider (AWS in this case)                     #
################################################################

provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file}"
  profile                 = "${var.profile}"
}

################################################################

################################################################
# Defining a vpc                                               #
################################################################

resource "aws_vpc" "terraform" {
  cidr_block           = "10.0.0.0/16"
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining a subnets (2 public and 2 private                   #
################################################################

resource "aws_subnet" "public_1" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${data.aws_availability_zones.all.names[0]}"
  map_public_ip_on_launch = true

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${data.aws_availability_zones.all.names[1]}"
  map_public_ip_on_launch = true

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = "${aws_vpc.terraform.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${data.aws_availability_zones.all.names[0]}"

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = "${aws_vpc.terraform.id}"
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${data.aws_availability_zones.all.names[1]}"

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining an EIP                                              #
################################################################

resource "aws_eip" "eip" {
  vpc = true
}

################################################################

################################################################
# Defining an NAT Gateway                                      #
################################################################

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id     = "${aws_subnet.public_1.id}"

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining an internet gateway                                 #
################################################################

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = "${aws_vpc.terraform.id}"

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining Routing Tables                                         #
################################################################

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.terraform.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gw.id}"
  }

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.terraform.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Setting the Rout Table Associations                          #
################################################################

resource "aws_route_table_association" "public-rt-1" {
  subnet_id      = "${aws_subnet.public_1.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_route_table_association" "public-rt-2" {
  subnet_id      = "${aws_subnet.public_2.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_route_table_association" "private-rt-1" {
  subnet_id      = "${aws_subnet.private_1.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_route_table_association" "private-rt-2" {
  subnet_id      = "${aws_subnet.private_2.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

################################################################

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
"ec2:DeleteNetworkInterface",
"states:*",
"s3:*"
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
  source = "/dev/null"
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
  subnet_ids  = ["${aws_subnet.public_1.id}", "${aws_subnet.public_2.id}"]
}

################################################################
# adding a RDS instance                                        #
################################################################

resource "aws_db_instance" "frbhackathon2018tf" {
  allocated_storage      = 10
  identifier             = "frbhackathon2018tf"
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7.23"
  instance_class         = "db.t2.micro"
  name                   = "frbhackathon2018tf"
  username               = "root"
  password               = "${var.rds_pass}"
  parameter_group_name   = "default.mysql5.7"
  publicly_accessible    = true
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.subnet_group.id}"
  skip_final_snapshot    = true

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# adding an SNS topic                                          #
################################################################

resource "aws_sns_topic" "sns_topic" {
  name = "frbhackathon_topic"
}

################################################################

################################################################
# adding an sfn role                                           #
################################################################

resource "aws_iam_role" "iam_for_sfn" {
  name = "iam_for_sfn"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "states.amazonaws.com"
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
# Defining a sfn role policy                                   #
################################################################

resource "aws_iam_policy" "sfn_role_policy" {
  name        = "sfn_role_policy"
  description = "Defines an sfn role policy"

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
"ec2:DeleteNetworkInterface",
"lambda:*"
],
"Resource": "*"
}
]
}
EOF
}

################################################################

################################################################
# Attaching the sfn role policy to sfn role                    #
################################################################

resource "aws_iam_role_policy_attachment" "attach_to_sfn_role" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "${aws_iam_policy.sfn_role_policy.arn}"
}

################################################################

################################################################
# Defining the AWS state machine                               #
################################################################

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "frbhackathon2018_state_machine"
  role_arn = "${aws_iam_role.iam_for_sfn.arn}"

  definition = <<EOF
{
"Comment": "A Catch example of the Amazon States Language using an AWS Lambda function",
"StartAt": "FileObfuscator",
"States": {
"FileObfuscator": {
"Type": "Task",
"Resource": "${aws_lambda_function.data_obfuscator.arn}",
"Next": "RDSInserter",
"Catch": [
{
"ErrorEquals": ["States.ALL"],
"Next": "Notifier"
}
]
},
"RDSInserter": {
"Type": "Task",
"Resource": "${aws_lambda_function.rds_inserter.arn}",
"End": true,
"Catch": [
{
"ErrorEquals": ["States.ALL"],
"Next": "Notifier"
}
]
},
"Notifier": {
"Type": "Pass",
"Result": "Failure!",
"End": true
}
}
}


EOF
}

################################################################

################################################################
# Defining the ec2 role                                        #
################################################################

resource "aws_iam_role" "iam_for_ec2" {
  name = "iam_for_ec2"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "ec2.amazonaws.com"
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
# Defining a ec2 role policy                                   #
################################################################

resource "aws_iam_policy" "ec2_role_policy" {
  name        = "ec2_role_policy"
  description = "Defines an ec2 role policy"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"s3:*"
],
"Resource": "*"
}
]
}
EOF
}

################################################################

################################################################
# Attaching the ec2 role policy to ec2 role                    #
################################################################

resource "aws_iam_role_policy_attachment" "attach_to_ec2_role" {
  role       = "${aws_iam_role.iam_for_ec2.name}"
  policy_arn = "${aws_iam_policy.ec2_role_policy.arn}"
}

################################################################

resource "aws_key_pair" "deployer" {
  key_name   = "frbhackathon2018"
  public_key = "${var.ssh_key}"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name  = "ec2_profile"
  roles = ["${aws_iam_role.iam_for_ec2.name}"]
}

################################################################
# Defining aws ec2 instance                                    #
################################################################

resource "aws_instance" "ec2-instance" {
  ami                    = "ami-01beb64058d271bc4"
  instance_type          = "t2.micro"
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_profile.name}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  subnet_id              = "${aws_subnet.public_1.id}"
  key_name               = "frbhackathon2018"

  user_data = <<EOF
"#!/bin/bash"
"pip install awscli --upgrade --user"
EOF

  tags {
    name = "frbhackathon2018"
  }
}

################################################################

################################################################
# Defining the AWS lambdas                                     #
################################################################

resource "aws_lambda_function" "sfn_triggerer" {
  filename      = "${path.module}${var.sfn_triggerer_lambda_function}"
  function_name = "sfn_triggerer"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "sfn_triggerer.lambda_handler"
  runtime       = "python3.6"

  vpc_config {
    subnet_ids         = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]
    security_group_ids = ["${aws_security_group.allow_all.id}"]
  }

  environment {
    variables = {
      sfn_arn = "${aws_sfn_state_machine.sfn_state_machine.id}"
    }
  }

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_lambda_function" "data_obfuscator" {
  filename      = "${path.module}${var.data_obfuscator_lambda_function}"
  function_name = "data_obfuscator"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "data_obfuscator.lambda_handler"
  runtime       = "python3.6"

  vpc_config {
    subnet_ids         = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]
    security_group_ids = ["${aws_security_group.allow_all.id}"]
  }

  environment {
    variables = {
      endpoint = "${aws_db_instance.frbhackathon2018tf.endpoint}"
      user     = "${aws_db_instance.frbhackathon2018tf.username}"
      password = "${aws_db_instance.frbhackathon2018tf.password}"
    }
  }

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_lambda_function" "rds_inserter" {
  filename      = "${path.module}${var.rds_inserter_lambda_function}"
  function_name = "rds_inserter"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "rds_inserter.lambda_handler"
  runtime       = "python3.6"

  vpc_config {
    subnet_ids         = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]
    security_group_ids = ["${aws_security_group.allow_all.id}"]
  }

  environment {
    variables = {
      endpoint = "${aws_db_instance.frbhackathon2018tf.endpoint}"
      user     = "${aws_db_instance.frbhackathon2018tf.username}"
      password = "${aws_db_instance.frbhackathon2018tf.password}"
    }
  }

  tags {
    name = "frbhackathon2018"
  }
}

resource "aws_lambda_function" "notifier" {
  filename      = "${path.module}${var.notifier_lambda_function}"
  function_name = "notifier"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "notifier.lambda_handler"
  runtime       = "python3.6"

  vpc_config {
    subnet_ids         = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]
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

output "rds_endpoint" {
  value = "${aws_db_instance.frbhackathon2018tf.endpoint}"
}

output "rds_username" {
  value = "${aws_db_instance.frbhackathon2018tf.username}"
}

output "rds_password" {
  value = "${aws_db_instance.frbhackathon2018tf.password}"
}

output "ec2_id" {
  value = "${aws_instance.ec2-instance.public_ip}"
}
