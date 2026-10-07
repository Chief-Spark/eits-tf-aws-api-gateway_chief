resource "aws_api_gateway_client_certificate" "this" {
  description = "${var.name}-client-cert"
  tags        = local.tags
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id           = aws_api_gateway_rest_api.this.id
  stage_name            = var.deployment.stage.stage_name
  deployment_id         = aws_api_gateway_deployment.this.id
  cache_cluster_enabled = var.deployment.stage.cache_cluster_enabled
  cache_cluster_size    = var.deployment.stage.cache_cluster_size
  client_certificate_id = aws_api_gateway_client_certificate.this.id
  description           = var.deployment.stage.description
  documentation_version = try(aws_api_gateway_documentation_version.this["enabled"].id, null)
  variables             = var.deployment.stage.variables
  xray_tracing_enabled  = var.deployment.stage.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = var.deployment.stage.access_log_destination_arn != null ? [1] : []

    content {
      destination_arn = var.deployment.stage.access_log_destination_arn
      format          = var.deployment.stage.access_log_format
    }
  }

  depends_on = [aws_api_gateway_account.global_settings]

  tags = local.tags
}

resource "aws_api_gateway_usage_plan" "this" {
  count = var.usage_plan == null ? 0 : 1

  name         = "${var.name}-usage-plan"
  description  = var.usage_plan.description
  product_code = var.usage_plan.product_code

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
    dynamic "throttle" {
      for_each = var.usage_plan.stage_throttles

      content {
        path        = throttle.value.path
        burst_limit = throttle.value.burst_limit
        rate_limit  = throttle.value.rate_limit
      }
    }
  }

  dynamic "quota_settings" {
    for_each = var.usage_plan.quota_settings == null ? [] : [1]

    content {
      limit  = var.usage_plan.quota_settings.limit
      offset = var.usage_plan.quota_settings.offset
      period = var.usage_plan.quota_settings.period
    }
  }

  dynamic "throttle_settings" {
    for_each = var.usage_plan.throttle_settings == null ? [] : [1]
    content {
      burst_limit = var.usage_plan.throttle_settings.burst_limit
      rate_limit  = var.usage_plan.throttle_settings.rate_limit
    }
  }

  tags = local.tags
}


resource "aws_api_gateway_deployment" "this" {
  description = var.deployment.description
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = var.deployment.triggers
  variables = var.deployment.variables
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_rest_api.this,
    aws_api_gateway_rest_api_policy.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_method.this,
    aws_api_gateway_resource.this,
    aws_api_gateway_integration_response.this,
    aws_api_gateway_method_response.this
  ]
}

resource "aws_api_gateway_method_settings" "this" {
  count = !local.use_openapi ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = var.method_settings.metrics_enabled
    logging_level                              = var.method_settings.logging_level
    data_trace_enabled                         = var.method_settings.data_trace_enabled
    throttling_burst_limit                     = var.method_settings.throttling_burst_limit
    throttling_rate_limit                      = var.method_settings.throttling_rate_limit
    caching_enabled                            = var.method_settings.caching_enabled
    cache_ttl_in_seconds                       = var.method_settings.cache_ttl_in_seconds
    cache_data_encrypted                       = var.method_settings.cache_data_encrypted
    require_authorization_for_cache_control    = var.method_settings.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.method_settings.unauthorized_cache_control_header_strategy
  }

  depends_on = [aws_api_gateway_account.global_settings]
}
