
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = var.rest-api-id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "200"

}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id       = var.rest-api-id
  resource_id       = var.resource_id
  http_method       = var.http_method
  status_code       = aws_api_gateway_method_response.response_200.status_code
  selection_pattern = ""

  depends_on = [
    var.integration
  ]



}



resource "aws_api_gateway_model" "error-404" {
  rest_api_id  = var.rest-api-id
  name         = "error404"
  description  = "404 error response schema"
  content_type = "application/json"

  schema = file("${path.module}/templates/schemas/_404.json")

}


resource "aws_api_gateway_model" "error-500" {
  rest_api_id  = var.rest-api-id
  name         = "error500"
  description  = "500 error response schema"
  content_type = "application/json"

  schema = file("${path.module}/templates/schemas/_500.json")

}



resource "aws_api_gateway_method_response" "response_404" {
  rest_api_id = var.rest-api-id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "404"

  response_models = {
    "application/json" = aws_api_gateway_model.error-404.name
  }
}


resource "aws_api_gateway_integration_response" "integration_response_404" {
  rest_api_id       = var.rest-api-id
  resource_id       = var.resource_id
  http_method       = var.http_method
  status_code       = aws_api_gateway_method_response.response_404.status_code
  selection_pattern = ".*not found.*"

  response_templates = {
    "application/json" = file("${path.module}/templates/get-method-404-integration-request.vtl")
  }

  depends_on = [
    var.integration
  ]


}


resource "aws_api_gateway_method_response" "response_500" {
  rest_api_id = var.rest-api-id
  resource_id = var.resource_id
  http_method = var.http_method
  status_code = "500"

  response_models = {
    "application/json" = aws_api_gateway_model.error-500.name
  }
}



resource "aws_api_gateway_integration_response" "integration_response_500" {
  rest_api_id       = var.rest-api-id
  resource_id       = var.resource_id
  http_method       = var.http_method
  status_code       = aws_api_gateway_method_response.response_500.status_code
  selection_pattern = ".*Server Error.*"
  response_templates = {
    "application/json" = file("${path.module}/templates/get-method-500-integration-request.vtl")
  }

  depends_on = [
    var.integration
  ]


}
