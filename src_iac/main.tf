
provider "aws" {
    region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec_role" {
    name = "lambda_exec_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Principal = {
                Service = "lambda.amazonaws.com"
            },
            Effect = "Allow",
            Sid    = ""
        }]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
    role = aws_iam_role.lambda_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
    s3_lambda_variables = [
        {
            s3_bucket_name       = "landing_zone_s3"
            lambda_function_name = "handler"
            lambda_zip_file      = "lambda_landingzoneprocess.zip"
        }
    ]
}

module "s3_lambda" {
    for_each = { for idx, pair in local.s3_lambda_variables : idx => pair }

    source                = "./modules/s3_lambda"
    s3_bucket_name        = each.value.s3_bucket_name
    lambda_function_name  = each.value.lambda_function_name
    lambda_zip_file       = each.value.lambda_zip_file
    lambda_handler        = "index.handler"
    lambda_runtime        = "python3.9"
    lambda_role_arn       = aws_iam_role.lambda_exec_role.arn
}
