variable "region" {
  default = "us-east-1"
}

variable "image_uri" {
  description = " ECR image URI for the lambda container"
  default     = "****-****-*****.dkr.ecr.us-east-1.amazonaws.com/my-lambda-image:latest"
}
