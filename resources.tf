resource "aws_api_gateway_resource" "this" {
  for_each = { for k, v in var.resources : k => v if !local.use_openapi }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = each.value.is_well_known ? aws_api_gateway_resource.well_known[0].id : aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "well_known" {
  count = !local.use_openapi && local.enable_well_known ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = ".well-known"
}

resource "aws_api_gateway_integration" "this" {
  for_each = { for method in local.methods : method.unique_id => method if try(method.integration, null) != null && !local.use_openapi }

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method             = each.value.http_method
  integration_http_method = each.value.integration.integration_method
  type                    = each.value.integration.type
  connection_id           = try(aws_api_gateway_vpc_link.this[0].id, null)
  connection_type         = each.value.integration.connection_type
  uri                     = each.value.integration.uri
  credentials             = each.value.integration.credentials
  request_templates       = each.value.integration.request_templates
  request_parameters      = each.value.integration.request_parameters
  passthrough_behavior    = each.value.integration.passthrough_behavior
  cache_key_parameters    = each.value.integration.cache_key_parameters
  cache_namespace         = each.value.integration.cache_namespace
  content_handling        = each.value.integration.content_handling
  timeout_milliseconds    = each.value.integration.timeout_milliseconds
  integration_target      = each.value.integration.integration_target
  response_transfer_mode  = each.value.integration.response_transfer_mode

  tls_config {
    insecure_skip_verification = false
  }

  depends_on = [aws_api_gateway_method.this]
}

resource "aws_api_gateway_integration_response" "this" {
  for_each = { for response in local.integration_responses : response.unique_id => response if !local.use_openapi }

  http_method         = each.value.http_method
  resource_id         = aws_api_gateway_resource.this[each.value.resource_key].id
  rest_api_id         = aws_api_gateway_rest_api.this.id
  status_code         = each.value.integration_response.status_code
  content_handling    = each.value.integration_response.content_handling
  response_parameters = each.value.integration_response.response_parameters
  response_templates  = each.value.integration_response.response_templates
  selection_pattern   = each.value.integration_response.selection_pattern

  depends_on = [aws_api_gateway_integration.this]
}

resource "aws_api_gateway_method" "this" {
  for_each = { for method in local.methods : method.unique_id => method if !local.use_openapi }

  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method          = each.value.http_method
  authorization        = each.value.authorization
  # Auto-assign the module authorizer to CUSTOM methods only when no explicit authorizer_id is provided at method level.
  authorizer_id        = each.value.authorization == "CUSTOM" && var.authorizer != null && each.value.authorizer_id == null ? aws_api_gateway_authorizer.this[0].id : each.value.authorizer_id
  operation_name       = each.value.operation_name
  request_models       = each.value.request_models
  request_parameters   = each.value.request_parameters
  request_validator_id = try(aws_api_gateway_request_validator.this[each.value.request_validator].id, null)
}

resource "aws_api_gateway_method_response" "this" {
  for_each = { for response in local.method_responses : response.unique_id => response if !local.use_openapi }

  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method         = each.value.http_method
  status_code         = each.value.status_code
  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters

  depends_on = [aws_api_gateway_method.this]
}
