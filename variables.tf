variable "api" {
  description = "API Gateway configuration"
  type = object({
    binary_media_types           = optional(list(string))
    description                  = optional(string)
    disable_execute_api_endpoint = optional(bool, true)
    minimum_compression_size     = optional(number, -1)
    parameters                   = optional(map(string))
    policy                       = optional(string)              // JSON string
    put_rest_api_mode            = optional(string, "overwrite") // "merge" or "overwrite"
    vpc_link_target_arns         = optional(list(string), [])
    tags                         = optional(map(string), {})
  })
  default = {}
}

variable "authorizer" {
  description = <<-DESC
    API Gateway authorizer configuration. The 'authorizer_uri' field accepts a Lambda function invoke ARN 
    (e.g., arn:aws:apigateway:REGION:lambda:path/2015-03-31/functions/LAMBDA_ARN/invocations).
    When var.authorizer is provided, it is automatically assigned to methods with authorization="CUSTOM" that have no explicit authorizer_id.
  DESC
  type = object({
    type                             = optional(string, "TOKEN") // TOKEN or REQUEST
    identity_source                  = optional(string, "method.request.header.Authorization")
    authorizer_uri                   = string
    authorizer_credentials           = optional(string)
    authorizer_result_ttl_in_seconds = optional(number, 300)
    identity_validation_expression   = optional(string)
  })
  default = null
}

variable "custom_domain_name" {
  description = "Domain name attributes. Provide either 'certificate_arn' or both 'certificate_body' and 'private_key'. If providing the 'certificate_body' and 'private_key', this must be as a file location"
  type = object({
    domain_name      = string
    certificate_arn  = optional(string)
    certificate_body = optional(string)
    private_key      = optional(string)
  })
  default = null

  validation {
    condition = var.custom_domain_name == null ? true : anytrue([
      var.custom_domain_name.certificate_arn == null && var.custom_domain_name.certificate_body != null && var.custom_domain_name.private_key != null,
      var.custom_domain_name.certificate_arn != null && var.custom_domain_name.certificate_body == null && var.custom_domain_name.private_key == null
    ])
    error_message = "Either 'certificate_arn' must be provided, or both 'certificate_body' and 'private_key' must be provided."
  }
}

variable "deployment" {
  description = "Definition of the API deployment and stage"
  type = object({
    description = optional(string)
    triggers    = optional(map(string))
    variables   = optional(map(string))
    stage = object({
      stage_name                 = string
      description                = optional(string)
      cache_cluster_enabled      = optional(bool, false)
      cache_cluster_size         = optional(string, "0.5")
      variables                  = optional(map(string))
      xray_tracing_enabled       = optional(bool, false)
      access_log_destination_arn = optional(string)
      access_log_format          = optional(string)
    })
  })
}

variable "documentation_parts" {
  description = "List of API Gateway documentation parts"
  type = list(object({
    location = object({
      method      = optional(string)
      name        = optional(string)
      path        = optional(string)
      status_code = optional(string)
      type        = string
    })
    properties = string
  }))
  default = []
}

variable "document_version" {
  description = "API Gateway documentation version"
  type = object({
    version     = string
    description = optional(string)
  })
  default = null
}

variable "external_eec_endpoints" {
  description = "Enable external EEC endpoints, defaults to false. Option ignored if providing own endpoint ID."
  type        = bool
  default     = false
}

variable "gateway_response" {
  description = "List of API Gateway gateway responses"
  type = object({
    response_type       = string
    status_code         = optional(string)
    response_parameters = optional(map(string))
    response_templates  = optional(map(string))
  })
  default = null
}

variable "method_settings" {
  description = "Settings for all methods"
  type = object({
    metrics_enabled                            = optional(bool, true)
    logging_level                              = optional(string, "INFO")
    data_trace_enabled                         = optional(bool, false)
    throttling_burst_limit                     = optional(number, -1)
    throttling_rate_limit                      = optional(number, -1)
    caching_enabled                            = optional(bool, true)
    cache_ttl_in_seconds                       = optional(number, 300)
    cache_data_encrypted                       = optional(bool, true)
    require_authorization_for_cache_control    = optional(bool, true)
    unauthorized_cache_control_header_strategy = optional(string, "FAIL_WITH_403")
  })
  default = {}
}

variable "models" {
  description = "API Gateway models"
  type = list(object({
    name         = string
    description  = optional(string)
    content_type = string
    schema       = string
  }))
  default = []
}

variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "open_api_json" {
  description = "OpenAPI/Swagger JSON specification for the API Gateway"
  type        = string
  default     = null
  validation {
    condition     = (var.open_api_json != null) != (length(var.resources) != 0)
    error_message = "Resources need to be defined by either using the 'resources' variable or by providing an OpenAPI/Swagger definition in body in the 'api' variable"
  }
}

variable "resources" {
  description = "List of API Gateway resources"
  type = map(object({
    is_well_known = optional(bool, false)
    methods = map(object({
      authorization      = string
      authorizer_id      = optional(string)
      operation_name     = optional(string)
      request_models     = optional(map(string))
      request_parameters = optional(map(string))
      request_validator  = optional(string)
      method_responses = optional(list(object({
        status_code         = string
        response_models     = optional(map(string))
        response_parameters = optional(map(string))
      })))
      integration = object({
        integration_method     = optional(string)
        type                   = string
        connection_type        = optional(string, "INTERNET")
        uri                    = optional(string)
        credentials            = optional(string)
        request_templates      = optional(map(string))
        request_parameters     = optional(map(string))
        passthrough_behavior   = optional(string)
        cache_key_parameters   = optional(list(string))
        cache_namespace        = optional(string)
        content_handling       = optional(string)
        timeout_milliseconds   = optional(number, 29000)
        integration_target     = optional(string)
        response_transfer_mode = optional(string, "BUFFERED")
      })
      integration_responses = optional(list(object({
        status_code         = string
        content_handling    = optional(string)
        response_parameters = optional(map(string))
        response_templates  = optional(map(string))
        selection_pattern   = optional(string)
      })))
    }))
  }))
  default = {}
  validation {
    condition     = alltrue(flatten([for name, definition in var.resources : [for method, value in definition.methods : contains(["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "PATCH", "ANY"], upper(method))]]))
    error_message = "Methods must be one of GET, POST, PUT, DELETE, HEAD, OPTIONS, PATCH or ANY"
  }
}

variable "usage_plan" {
  description = "Usage plan settings for the stage"
  type = object({
    description  = optional(string)
    product_code = optional(string)
    stage_throttles = optional(list(object({
      path        = string
      burst_limit = optional(number, -1)
      rate_limit  = optional(number, -1)
    })), [])
    quota_settings = optional(object({
      limit  = optional(number, -1)
      offset = optional(number, 0)
      period = optional(string, "DAY")
    }))
    throttle_settings = optional(object({
      burst_limit = optional(number, -1)
      rate_limit  = optional(number, -1)
    }))
  })
  default = null
}

variable "validators" {
  description = "List of named validators"
  type = list(object({
    name                        = string
    validate_request_body       = optional(bool, false)
    validate_request_parameters = optional(bool, false)
  }))
  default = []
}

variable "vpc_endpoint_ids" {
  description = "List of API endpoint IDs. Defaults to regional EEC endpoints"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Resource tags, see https://pages.experian.local/spaces/SC/pages/400041906/Cloud+Tagging+Strategy+Standards"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_role_name" {
  description = "Name for the API Gateway CloudWatch role. Only change if you need a custom name. Default is 'BURoleForAPIGatewayCloudwatchGlobal'."
  type        = string
  default     = "BURoleForAPIGatewayCloudwatchGlobal"
}

variable "create_cloudwatch_role" {
  description = "Whether this module creates the API Gateway CloudWatch role. If false, a role matching 'cloudwatch_role_name' must already exist."
  type        = bool
  default     = true
}

variable "cloudwatch_attach_policy_inline" {
  description = "When set to true, CloudWatch logging permissions are attached as an inline role policy instead of a standalone managed policy. Use this when your environment restricts creation of IAM managed policies."
  type        = bool
  default     = false
}

variable "permissions_boundary" {
  description = "ARN of the IAM policy to use as a permissions boundary for the CloudWatch IAM role. If not set, no permissions boundary is applied."
  type        = string
  default     = null
}
