data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "files_clueless_engineer" {
  domain = var.api_gateway_custom_domain_name
  types  = ["AMAZON_ISSUED"]
}

