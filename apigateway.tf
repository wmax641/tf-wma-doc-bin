resource "aws_apigatewayv2_api" "api_gateway" {
  name          = var.base_name
  protocol_type = "HTTP"

  tags = merge({ "Name" = var.base_name }, var.common_tags)
}

resource "aws_apigatewayv2_integration" "getfile" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Get file from s3"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.getfile.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "getfile" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /getfile"

  target = "integrations/${aws_apigatewayv2_integration.getfile.id}"
}

resource "aws_lambda_permission" "lambda_permission_getfile" {
  statement_id  = "allow_api_gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getfile.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  description = "deployment!!"

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_apigatewayv2_route.getfile,
  ]
}

resource "aws_apigatewayv2_stage" "v1" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "v1"
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "files_clueless_engineer" {
  domain_name = var.api_gateway_custom_domain_name

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.files_clueless_engineer.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "files_clueless_engineer" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  domain_name = aws_apigatewayv2_domain_name.files_clueless_engineer.id
  stage       = aws_apigatewayv2_stage.v1.id
}


