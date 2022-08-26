terraform {
  backend "s3" {
    bucket  = "terraform-agtsoltns-state-versions"
    region  = "eu-west-1"
    key     = "dev1-blue/terraform.tfstate"
    profile = "ci-agent"
  }
}
