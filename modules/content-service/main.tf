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




resource "aws_api_gateway_resource" "content-service" {
  rest_api_id = data.aws_ssm_parameter.rest-api-id.value
  parent_id   = data.aws_ssm_parameter.root-resource-id.value
  path_part   = "content-service"

}

resource "aws_api_gateway_resource" "v2" {
  rest_api_id = data.aws_ssm_parameter.rest-api-id.value
  parent_id   = aws_api_gateway_resource.content-service.id
  path_part   = "v2"

}


resource "aws_api_gateway_request_validator" "get-method" {
  name                        = "QueryRequestValidator"
  rest_api_id                 = data.aws_ssm_parameter.rest-api-id.value
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "get-method" {
  rest_api_id      = data.aws_ssm_parameter.rest-api-id.value
  resource_id      = aws_api_gateway_resource.v2.id
  api_key_required = true
  authorization    = "NONE"
  http_method      = "GET"

  request_parameters = {
    "method.request.querystring.contentEntryKey" = true
    "method.request.querystring.contentType"     = true
  }

  request_validator_id = aws_api_gateway_request_validator.get-method.id

}


resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = data.aws_ssm_parameter.rest-api-id.value
  resource_id             = aws_api_gateway_resource.v2.id
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.get-method.http_method
  type                    = "AWS"

  uri                  = aws_lambda_function.content-v2-asset.invoke_arn
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = file("./utils/get-method-integration-request.vtl")
  }


}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.content-v2-asset.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws-region}:${var.aws-account-id}:${data.aws_ssm_parameter.rest-api-id.value}/*/GET/${aws_api_gateway_resource.content-service.path_part}/${aws_api_gateway_resource.v2.path_part}"
}




module "method-models" {
  source      = "../../modules/api-gateway-response-schemas"
  rest-api-id = data.aws_ssm_parameter.rest-api-id.value
  resource_id = aws_api_gateway_resource.v2.id
  http_method = aws_api_gateway_method.get-method.http_method

  integration = aws_api_gateway_integration.integration


}




resource "aws_api_gateway_deployment" "api-deployment" {
  description = "Automatic deployment"
  depends_on = [
    aws_api_gateway_method.get-method,
    aws_api_gateway_integration.integration
  ]

  rest_api_id = data.aws_ssm_parameter.rest-api-id.value
  stage_name  = var.environment

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.content-service,
      aws_api_gateway_resource.v2,
      aws_api_gateway_integration.integration,
      aws_api_gateway_method.get-method
      ]
      ))
  }

  lifecycle {
    create_before_destroy = true
  }
}
