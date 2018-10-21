################################################################
# Infrastructure variables to be read from variables.tfvars    #
################################################################

variable "region" {}
variable "shared_credentials_file" {}
variable "profile" {}
variable "sfn_triggerer_lambda_function" {}

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
# Defining the AWS lambdas                                     #
################################################################

resource "aws_lambda_function" "sfn_triggerer" {
  filename         = "${var.sfn_triggerer_lambda_function}"
  function_name    = "sfn_triggerer_tf"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "sfn_triggerer_tf.lambda_handler"
  runtime          = "python3.6"
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