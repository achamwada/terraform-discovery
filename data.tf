data "aws_ssm_parameter" "vpc-id" {
  name = "/dx/infra/vpc/default/vpc-id"

}


data "aws_vpc" "selected" {
  id = "vpc-005f6430066550879"
}




data "aws_availability_zones" "available" {}




data "aws_security_group" "default-sg" {
  vpc_id = data.aws_vpc.selected.id
  name   = "default"
}




data "aws_iam_policy_document" "apigw" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["execute-api:Invoke"]
    resources = ["*"]
  }

  statement {
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["execute-api:Invoke"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values = [aws_vpc_endpoint.digital.id]
    }
  }
}

data "aws_vpc_endpoint_service" "digital" {
  service = "execute-api"
}