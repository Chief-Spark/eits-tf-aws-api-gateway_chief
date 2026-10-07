resource "aws_api_gateway_rest_api" "this" {
  binary_media_types           = local.use_openapi ? null : var.api.binary_media_types
  body                         = var.open_api_json
  description                  = local.use_openapi ? null : var.api.description
  disable_execute_api_endpoint = local.use_openapi ? null : var.api.disable_execute_api_endpoint
  minimum_compression_size     = local.use_openapi ? null : var.api.minimum_compression_size
  name                         = "${var.name}-api"
  parameters                   = local.use_openapi ? null : var.api.parameters
  put_rest_api_mode            = local.use_openapi ? null : var.api.put_rest_api_mode

  endpoint_configuration {
    ip_address_type  = "dualstack"
    types            = ["PRIVATE"]
    vpc_endpoint_ids = toset(local.vpc_endpoints)
  }

  tags = local.tags
}

resource "aws_api_gateway_documentation_part" "this" {
  for_each = toset([for part in var.documentation_parts : part if var.document_version != null])

  properties  = each.value.properties
  rest_api_id = aws_api_gateway_rest_api.this.id
  location {
    method      = each.value.location.method
    name        = each.value.location.name
    path        = each.value.location.path
    status_code = each.value.location.status_code
    type        = each.value.location.type
  }
}

resource "aws_api_gateway_documentation_version" "this" {
  count = length(var.documentation_parts) != 0 && var.document_version != null ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  version     = var.document_version.version
  description = var.document_version.description
  depends_on  = [aws_api_gateway_documentation_part.this]
}

resource "aws_api_gateway_gateway_response" "this" {
  count = var.gateway_response != null && !local.use_openapi ? 1 : 0

  rest_api_id         = aws_api_gateway_rest_api.this.id
  response_type       = var.gateway_response.response_type
  status_code         = var.gateway_response.status_code
  response_templates  = var.gateway_response.response_templates
  response_parameters = var.gateway_response.response_parameters
}

resource "aws_api_gateway_model" "this" {
  for_each = { for model in var.models : model.name => model if !local.use_openapi }

  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = each.value.name
  description  = each.value.description
  content_type = each.value.content_type
  schema       = each.value.schema
}

resource "aws_api_gateway_request_validator" "this" {
  for_each = { for validator in var.validators : validator.name => validator }

  name                        = each.value.name
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  validate_request_body       = each.value.validate_request_body
  validate_request_parameters = each.value.validate_request_parameters
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = var.api.policy == null ? data.aws_iam_policy_document.default.json : var.api.policy
}

resource "aws_api_gateway_vpc_link" "this" {
  count = length(var.api.vpc_link_target_arns) > 0 ? 1 : 0

  name        = "${var.name}-vpc-link"
  description = "List of VPC endpoint ARNs for ${var.name}"
  target_arns = var.api.vpc_link_target_arns
  tags        = local.tags
}

resource "aws_api_gateway_authorizer" "this" {
  count = var.authorizer != null ? 1 : 0

  name            = "${var.name}-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.this.id
  type            = var.authorizer.type
  identity_source = var.authorizer.identity_source

  authorizer_uri                   = var.authorizer.authorizer_uri
  authorizer_credentials           = var.authorizer.authorizer_credentials
  authorizer_result_ttl_in_seconds = var.authorizer.authorizer_result_ttl_in_seconds
  identity_validation_expression   = var.authorizer.identity_validation_expression
}
