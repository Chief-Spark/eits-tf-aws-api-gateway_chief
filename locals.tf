module "eits_ce_common" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-ce-common.git?ref=v1"

  module_repo = "eits-tf-aws-api-gateway"
  tags        = var.tags
}

locals {
  # Checks if the CloudWatch role already exists in the account to avoid duplicate creation.
  # Known issue: subsequent applies may trigger destroy/recreate of aws_api_gateway_account — fix pending in upcoming sprint.
  cloudwatch_role_exists = length(data.aws_iam_roles.cloudwatch_role.arns) > 0
  
  use_openapi           = var.open_api_json != null
  tags                  = merge(var.tags, module.eits_ce_common.tags)
  environment           = lookup(merge(data.aws_default_tags.current.tags, local.tags), "Environment", "na")
  enable_well_known     = anytrue([for k, v in var.resources : v.is_well_known])
  methods               = flatten([for key, value in var.resources : [for method_key, method_value in try(value.methods, {}) : merge(
    { 
      unique_id = "${key}-${method_key}",
      resource_key = key,
      http_method = upper(method_key),
      # Keep original authorizer_id if provided, otherwise set to null for non-CUSTOM methods
      authorizer_id = try(method_value.authorizer_id, null)
    }, 
    method_value
  )]])
  method_responses      = try(flatten([for method in local.methods : [for response in try(method.method_responses, []) : merge({ unique_id = "${method.unique_id}-${response.status_code}", resource_key = method.resource_key, http_method = upper(method.http_method) }, response)]]), [])
  integration_responses = try(flatten([for method in local.methods : [for response in try(method.integration_responses, []) : merge({ unique_id = "${method.unique_id}-${response.status_code}", resource_key = method.resource_key, http_method = upper(method.http_method) }, response)]]), [])

  // EEC e-Connect v3 VPC Endpoints
  endpoint_map = {
    internal_eec_endpoints = {
      us-east-1    = "vpce-099b9bad5f18ee5a1"
      us-west-2    = "vpce-07698fe84e7d065db"
      eu-west-2    = "vpce-070c8384f2397b727"
      eu-central-1 = "vpce-008005c557ff03c60"
    }
    external_eec_endpoints = local.environment == "prd" ? {
      us-east-1    = "vpce-065f77986c4520405"
      us-west-2    = "vpce-0effbaea7b26ed978"
      sa-east-1    = "vpce-09a09846994a88068"
      eu-west-2    = "vpce-0099ac841e2e26a32"
      eu-central-1 = "vpce-0ecdc0abcf100e958"
      ca-central-1 = "vpce-0825e8432811dcbbe"
      } : {
      us-east-1    = "vpce-07e489ec9e16e98cd"
      us-west-2    = "vpce-03a270d74b6115b96"
      sa-east-1    = "vpce-05b804da86e894337"
      eu-west-2    = "vpce-0d74e16101c9ea098"
      eu-central-1 = "vpce-04cf7afe104ce40f0"
      ca-central-1 = "vpce-011a87511c499c171"
    }
  }
  location = var.external_eec_endpoints ? "external_eec_endpoints" : "internal_eec_endpoints"

  vpc_endpoints = var.vpc_endpoint_ids == null ? [lookup(local.endpoint_map[local.location], data.aws_region.current_region.region, [])] : var.vpc_endpoint_ids

}
