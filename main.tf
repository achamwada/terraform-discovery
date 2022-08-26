provider "aws" {
  profile = "ci-agent"
}

resource "aws_vpc_endpoint" "digital" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = data.aws_vpc_endpoint_service.digital.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = ["subnet-01289d2536c08a97a","subnet-01c949841f0dc1bd6","subnet-0e17b95d1adc95130"]
  security_group_ids = [data.aws_security_group.default-sg.id]

  tags = {
    Name = "dx-${var.environment}-apigw-endpoint"
  }


}

resource "aws_api_gateway_rest_api" "digital" {
  name = "dx-${var.environment}-apigw"

  policy = data.aws_iam_policy_document.apigw.json

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.digital.id]
  }

}

resource "aws_ssm_parameter" "rest-api-id" {
  name        = "/dx/infra/api-gw/${var.environment}/rest-api-id"
  description = "${var.environment} rest api id"
  type        = "String"
  value       = aws_api_gateway_rest_api.digital.id

  tags = {
    environment = "production"
  }
}

resource "aws_ssm_parameter" "root-resource-id" {
  name        = "/dx/infra/api-gw/${var.environment}/root-resource-id"
  description = "${var.environment} root resource id"
  type        = "String"
  value       = aws_api_gateway_rest_api.digital.root_resource_id

  tags = {
    environment = "production"
  }
}



module "content-service" {
  source      = "./modules/content-service"
  environment = var.environment
  aws-region = var.aws-region
  aws-account-id = var.aws-account-id
}

