resource "aws_route53_zone" "files_clueless_engineer" {
  name = var.api_gateway_custom_domain_name
  tags = merge({ "Name" = var.base_name }, var.common_tags)
}

resource "aws_route53_record" "example" {
  name    = var.api_gateway_custom_domain_name
  type    = "A"
  zone_id = aws_route53_zone.files_clueless_engineer.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.files_clueless_engineer.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.files_clueless_engineer.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
