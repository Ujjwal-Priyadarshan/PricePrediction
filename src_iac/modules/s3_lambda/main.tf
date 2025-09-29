# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}

# Lambda function
resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_function_name
  role          = var.lambda_role_arn
  # handler       = var.lambda_handler
  # runtime       = var.lambda_runtime
  # filename      = var.lambda_zip_file
  package_type = "Image"
  image_uri = var.lambda_img_source
  # source_code_hash = filebase64sha256(var.lambda_zip_file)
  # layers        = var.lambda_layers_arn
  timeout       = 60
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# resource "aws_iam_policy" "read_s3" {
#   name        = "read_s3_${var.s3_bucket_name}"
#   description = "Allow Lambda to read from ${var.s3_bucket_name} bucket"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ],
#         Resource = [
#           "arn:aws:s3:::${var.s3_bucket_name}",
#           "arn:aws:s3:::${var.s3_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
#   role       = var.lambda_role_name
#   policy_arn = aws_iam_policy.read_s3.arn
# }