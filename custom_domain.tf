module "acm" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-acm.git?ref=2.3.2"
  count  = try(var.custom_domain_name.certificate_body, null) == null ? 0 : 1

  action = "import"

  import_certificate = {
    private_key      = file(var.custom_domain_name.private_key)
    certificate_body = file(var.custom_domain_name.certificate_body)
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.custom_domain_name == null ? 0 : 1

  api_id      = aws_api_gateway_rest_api.this.id
  stage       = aws_api_gateway_stage.this.stage_name
  domain_name = var.custom_domain_name.domain_name

  depends_on = [aws_apigatewayv2_domain_name.this]
}

resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_domain_name == null ? 0 : 1

  domain_name = var.custom_domain_name.domain_name

  domain_name_configuration {
    certificate_arn = var.custom_domain_name.certificate_arn != null ? var.custom_domain_name.certificate_arn : module.acm.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = local.tags

  depends_on = [module.acm]
}
