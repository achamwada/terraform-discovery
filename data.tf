locals {
  base_api_gateway_resources_ssm_path = "/dx/infra/api-gw/${var.environment}"
}

data "aws_ssm_parameter" "rest-api-id" {
  name = "${local.base_api_gateway_resources_ssm_path}/rest-api-id"

}

data "aws_ssm_parameter" "root-resource-id" {
  name = "${local.base_api_gateway_resources_ssm_path}/root-resource-id"

}
