terraform {
  backend "s3" {
    bucket  = "terraform-discovery-state-versions"
    region  = "eu-west-1"
    key     = "dev1-blue/terraform.tfstate"
    profile = "deploy-agent"
  }
}
