terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">=4.19.0"
  }

}

variable "environment" {
  type    = string
  default = "non-prod"

}

provider "aws" {
  profile = "deploy-agent"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"       = "${var.environment}-vpc"
    "created_by" = "Terraform"
  }
}
