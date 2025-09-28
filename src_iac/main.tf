
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

locals {
    s3_lambda_variables = [
        {
            s3_bucket_name       = "ujp.landing.zone"
            lambda_function_name = "landing_handler"
            lambda_handler       = "landingzoneprocess.handler"
            lambda_zip_file      = "lambda_landing.zip"
            lambda_layers        = [
                # aws_lambda_layer_version.lambda_layer.arn
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-pandas:25",
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-boto3:30",
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-numpy:16"
            ]
        }
        ,{
            s3_bucket_name       = "ujp.curated.zone"
            lambda_function_name = "curated_handler"
            lambda_handler       = "curatedzoneprocess.handler"
            lambda_zip_file      = "lambda_curated.zip"
            lambda_layers        = [
                # aws_lambda_layer_version.lambda_layer.arn
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-pandas:25",
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-boto3:30",
                "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-numpy:16",
                #"arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p310-scipy:3"
            ]
        }
    ]
}

module "s3_lambda" {
    for_each = { for idx, pair in local.s3_lambda_variables : idx => pair }

    source                = "./modules/s3_lambda"
    s3_bucket_name        = each.value.s3_bucket_name
    lambda_function_name  = each.value.lambda_function_name
    lambda_zip_file       = each.value.lambda_zip_file
    lambda_handler        = each.value.lambda_handler
    lambda_role_arn       = aws_iam_role.lambda_exec_role.arn
    lambda_role_name      = aws_iam_role.lambda_exec_role.name
    lambda_layers_arn     = each.value.lambda_layers
}
