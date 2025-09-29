
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
            lambda_img_source    = "895636586106.dkr.ecr.us-east-1.amazonaws.com/lambda_landing_img:latest"
        }
        ,{
            s3_bucket_name       = "ujp.curated.zone"
            lambda_function_name = "curated_handler"
            lambda_handler       = "curatedzoneprocess.handler"
            lambda_img_source      = "895636586106.dkr.ecr.us-east-1.amazonaws.com/lambda_curated_img:latest"
        }
    ]
}

module "s3_lambda" {
    for_each = { for idx, pair in local.s3_lambda_variables : idx => pair }

    source                = "./modules/s3_lambda"
    s3_bucket_name        = each.value.s3_bucket_name
    lambda_function_name  = each.value.lambda_function_name
    lambda_img_source       = each.value.lambda_img_source
    lambda_handler        = each.value.lambda_handler
    lambda_role_arn       = aws_iam_role.lambda_exec_role.arn
    # lambda_role_name      = aws_iam_role.lambda_exec_role.name
    # lambda_layers_arn     = each.value.lambda_layers
}



resource "aws_s3_bucket" "bucket_target" {
  bucket = "ujp.target.zone"
}

resource "aws_iam_policy" "policy_s3" {
  name        = "policy_target_s3"
  description = "Allow access to bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
            "arn:aws:s3:::ujp.landing.zone",
            "arn:aws:s3:::ujp.curated.zone",
            "arn:aws:s3:::ujp.target.zone",
            "arn:aws:s3:::ujp.landing.zone/*",
            "arn:aws:s3:::ujp.curated.zone/*",
            "arn:aws:s3:::ujp.target.zone/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_role_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.policy_s3.arn
}