
variable "s3_bucket_name" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_img_source" {
  type = string
}

variable "lambda_handler" {
  type    = string
  default = "index.handler"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.10"
}

variable "lambda_role_arn" {
  type = string
}

# variable "lambda_role_name" {
#   type = string
# }

# variable "lambda_layers_arn" {
#   type = list(string)
# }