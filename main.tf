terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">=4.19.0"
  }

}

variable "account" {
  type    = string
  default = "non-prod"

}

variable "environment" {
  type    = string
  default = "dev1-blue"

}

variable "rest-api-id" {
  type    = string
  default = "10c810tp72"

}

variable "root-resource-id" {
  type    = string
  default = "4ryexcq2n3"

}

provider "aws" {
  profile = "deploy-agent"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name       = "${var.account}-vpc"
    created_by = "Terraform"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = file("./iam-policies/lambda-assume-role.json")
}
resource "aws_lambda_function" "content-v2-asset" {
  function_name = "dal-content-asset-api-v2-lambda-${var.environment}"
  handler       = "code/index.handler"
  filename      = "code.zip"
  runtime       = "nodejs16.x"
  role          = aws_iam_role.iam_for_lambda.arn
  architectures = ["x86_64"]
  timeout       = 90

  environment {
    variables = {
      DD_ENV          = var.environment
      DD_SERVICE      = "dal-content-asset-api-v2-lambda-${var.environment}"
      DD_VERSION      = "1234567"
      environmentName = var.environment
      isPreview       = "false"
    }
  }
}

resource "aws_api_gateway_resource" "content" {
  rest_api_id = var.rest-api-id
  parent_id   = var.root-resource-id
  path_part   = "content"

}

resource "aws_api_gateway_resource" "v2" {
  rest_api_id = var.rest-api-id
  parent_id   = aws_api_gateway_resource.content.id
  path_part   = "v2"

}

resource "aws_api_gateway_request_validator" "get-method" {
  name                        = "QueryRequestValidator"
  rest_api_id                 = var.rest-api-id
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "get-method" {
  rest_api_id      = var.rest-api-id
  resource_id      = aws_api_gateway_resource.v2.id
  api_key_required = false
  authorization    = "NONE"
  http_method      = "GET"
  # request_models = {
  #   "application/json" = "Error"
  # }
  request_parameters = {
    "method.request.querystring.contentEntryKey" = true
    "method.request.querystring.contentType"     = true
  }

  request_validator_id = aws_api_gateway_request_validator.get-method.id

}


resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.rest-api-id
  resource_id             = aws_api_gateway_resource.v2.id
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.get-method.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.content-v2-asset.invoke_arn


}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.content-v2-asset.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:927362808381:${var.rest-api-id}/test-invoke-stage/GET/${aws_api_gateway_resource.content.path_part}/${aws_api_gateway_resource.v2.path_part}"
}

