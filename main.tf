provider "aws" {
 region = var.region
}

resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
 count = 2
 vpc_id = aws_vpc.main.id
 cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
 map_public_ip_on_launch = true
 availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private" {
 count = 2
 vpc_id = aws_vpc.main.id
 cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 2)
 availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
 count = 1
 vpc = true
}

resource "aws_nat_gateway" "nat" {
 allocation_id = aws_eip.nat[0].id
 subnet_id = aws_subnet.public[0].id
}

resource "aws_route_table" "public" {
 vpc_id = aws_vpc.main.id

 route {
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.gw.id
 }
}

resource "aws_route_table" "private" {
 vpc_id = aws_vpc.main.id

 route {
 cidr_block = "0.0.0.0/0"
 nat_gateway_id = aws_nat_gateway.nat.id
 }
}

resource "aws_route_table_association" "public" {
 count = 2
 subnet_id = aws_subnet.public[count.index].id
 route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
 count = 2
 subnet_id = aws_subnet.private[count.index].id
 route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "lambda_exec" {
 name = "lambda_exec_role"

 assume_role_policy = jsonencode({
 Version = "2012-10-17",
 Statement = [{
 Action = "sts:AssumeRole",
 Effect = "Allow",
 Principal = {
 Service = "lambda.amazonaws.com"
 }
 }]
 })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
 role = aws_iam_role.lambda_exec.name
 policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "container_lambda" {
 function_name = "my-container-lambda"
 package_type = "Image"
 image_uri = var.image_uri
 role = aws_iam_role.lambda_exec.arn
 vpc_config {
 subnet_ids = aws_subnet.private[*].id
 security_group_ids = [aws_security_group.lambda_sg.id]
 }
 timeout = 30
}

resource "aws_security_group" "lambda_sg" {
 name = "lambda_sg"
 description = "Allow internal access"
 vpc_id = aws_vpc.main.id

 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_apigatewayv2_api" "http_api" {
 name = "lambda-http-api"
 protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
 api_id = aws_apigatewayv2_api.http_api.id
 integration_type = "AWS_PROXY"
 integration_uri = aws_lambda_function.container_lambda.invoke_arn
 integration_method = "POST"
 payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
 api_id = aws_apigatewayv2_api.http_api.id
 route_key = "GET /"
 target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
 api_id = aws_apigatewayv2_api.http_api.id
 name = "$default"
 auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
 statement_id = "AllowAPIGatewayInvoke"
 action = "lambda:InvokeFunction"
 function_name = aws_lambda_function.container_lambda.function_name
 principal = "apigateway.amazonaws.com"
 source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

data "aws_availability_zones" "available" {}