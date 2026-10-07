# EITS Terraform module API Gateway

EITS Terraform module for API Gateway.

This module will:

- Create a RESTful AWS API Gateway
- Create as a 'PRIVATE' API
- Create a single deployment and stage
- Allow for using OpenAPI/Swagger definitions (Optional)
- Import domain certificates into ACM (Optional)
- Create a default resource policy based on EEC endpoints
- Allow for specifying an authorizer
- Set up role for regional Cloudwatch logging (or use an existing role)

This module does not:

- Allow for multiple deployments or stages
- Allow for Canary settings to be set
- Allow for nested paths (without using an OpenAPI/Swagger document)

By default this module will only create a flat structure with no nested paths, 
with the caveat that you can also define `.well-known` resources too, IE

```text
Rest-API/
├─ .well-known/
│  ├─ well-known-resource-1
│  ├─ well-known-resource-2
├─ resource-1
├─ resource-2
...
```

To generate a more complex nested structure, you will need to provide an 
[OpenAPI/Swagger] JSON definition instead using [AWS specific extensions] to 
acheive the desired structure. If you do provide this spec, the `api` variable 
will be ignored. You will also get an error if you attempt to specify both OpenAPI
resources and anything via the `resources` variable.

When creating the API the module will by default try and link to an EEC internal
`execute-api` endpoint. To link to an external endpoint, you'll also need to set
the `external_eec_endpoint` to `true`. This is overridden if an endpoint(s) are
explicilty supplied: More information on the endpoints can be found with the
following links:

- [E-Connect (v3) AWS CSSv3 -  VPC EndPoints]
- [Internal connectivity]

See CHANGELOG.md for the list of changes for each release.
*We highly recommend that in your code you pin the version to the exact version 
you are using so that your infrastructure remains stable, and update versions in
a systematic way so that they do not catch you by surprise.*


## EITS Security & Compliance

**Last Module Review**: 2026-05-07

See below for the date and results of our EITS security and compliance scanning.
 
<!-- BEGIN_BENCHMARK_TABLE -->
| Benchmark | Date | Version | Description |
| --------- | ---- | ------- | ----------- |
| ![validate](https://img.shields.io/badge/validate-passed-green) | 2026-07-16 | 1.14.8 | Validates terraform code using example test directories |
| ![tflint](https://img.shields.io/badge/tflint-passed-green) | 2026-07-16 | 0.61.0 | Enforces best practices, syntax, naming conventions |
| ![trivy](https://img.shields.io/badge/trivy-passed-green) | 2026-07-16 | 0.72.0 | Detects misconfiguration in IaC files, such as Docker, Terraform, etc |
| ![wiz](https://img.shields.io/badge/wiz.io_iac-passed-green) | 2026-07-16 | 1.59.0 | Scans tests directory plans for vulnerabilities and risks |
<!-- END_BENCHMARK_TABLE -->

## Notes on CloudWatch Role

By default, this module creates the API Gateway CloudWatch role. If the role already exists in your account and you receive an "IAM role already exists" error, set `create_cloudwatch_role` to `false` and ensure `cloudwatch_role_name` matches the existing role.

## Usage

### Basic Example

```HCL
module "api" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-api-gateway.git?ref=1.0.0"

  name = "example"
  api = {
    description = "Example API Gateway"
  }
  deployment = {
    stage = {
      stage_name  = "example-stage"
      description = "Example Stage"
    }
  }
  resources = {
    my_app = {
      methods = {
        get = {
          authorization = "NONE",
          integration = {
            type = "MOCK"
          }
        }
      }
    }
  }

  tags = {
    CostString = <COSTSTRING_HERE>
    Environment = <ENVIRONMENT_HERE>
    AppID = <APPID_HERE>
  }
}
```

### Lambda Authorizer Example

```HCL
module "authorizer_lambda" {
  source = "git::ssh://git@code.experian.local/CFTD/splatam-tf-aws-lambda.git?ref=1.0.0"
  
  prefix        = "dev-123456789012"
  function_name = "my-authorizer"
  filename      = "./lambda.zip"
  runtime       = "python3.11"
  handler       = "authorizer.lambda_handler"
  # ... other Lambda configuration
}

module "api" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-api-gateway.git?ref=1.0.0"

  name = "example"
  
  # Pass the Lambda invoke ARN to automatically create authorizer
  authorizer_lambda_invoke_arn = module.authorizer_lambda.invoke_arn
  
  deployment = {
    stage = {
      stage_name = "example-stage"
    }
  }
  
  resources = {
    protected_resource = {
      methods = {
        get = {
          # CUSTOM authorization automatically uses the Lambda authorizer
          authorization = "CUSTOM"
          integration = {
            type = "MOCK"
          }
        }
      }
    }
  }

  tags = {
    CostString = <COSTSTRING_HERE>
    Environment = <ENVIRONMENT_HERE>
    AppID = <APPID_HERE>
  }
}
```

### Open API Example

```HCL
module "api" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-api-gateway.git?ref=1.0.0"

  name = "example"
  open_api_json = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/my_app" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "MOCK"
          }
        }
      }
    }
  })

  deployment = {
    stage = {
      stage_name  = "example-stage"
      description = "Example Stage"
    }
  }

  tags = {
    CostString = <COSTSTRING_HERE>
    Environment = <ENVIRONMENT_HERE>
    AppID = <APPID_HERE>
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.25.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.25.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | git::https://code.experian.local/scm/EUCES/eits-tf-aws-acm.git | 2.3.2 |
| <a name="module_cloudwatch_role"></a> [cloudwatch\_role](#module\_cloudwatch\_role) | git::https://code.experian.local/scm/EUCES/eits-tf-aws-iam.git | 1.9.7 |
| <a name="module_eits_ce_common"></a> [eits\_ce\_common](#module\_eits\_ce\_common) | git::https://code.experian.local/scm/EUCES/eits-tf-aws-ce-common.git | v1 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_account.global_settings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_api_gateway_authorizer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_api_gateway_client_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_client_certificate) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_documentation_part.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_documentation_part) | resource |
| [aws_api_gateway_documentation_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_documentation_version) | resource |
| [aws_api_gateway_gateway_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_gateway_response) | resource |
| [aws_api_gateway_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_model.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_model) | resource |
| [aws_api_gateway_request_validator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_request_validator) | resource |
| [aws_api_gateway_resource.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.well_known](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_rest_api_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api_policy) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_usage_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_apigatewayv2_api_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_iam_role_policy.cloudwatch_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_region.current_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api"></a> [api](#input\_api) | API Gateway configuration | <pre>object({<br/>    binary_media_types           = optional(list(string))<br/>    description                  = optional(string)<br/>    disable_execute_api_endpoint = optional(bool, true)<br/>    minimum_compression_size     = optional(number, -1)<br/>    parameters                   = optional(map(string))<br/>    policy                       = optional(string)              // JSON string<br/>    put_rest_api_mode            = optional(string, "overwrite") // "merge" or "overwrite"<br/>    vpc_link_target_arns         = optional(list(string), [])<br/>    tags                         = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_authorizer"></a> [authorizer](#input\_authorizer) | API Gateway authorizer configuration. The 'authorizer\_uri' field accepts a Lambda function invoke ARN <br/>(e.g., arn:aws:apigateway:REGION:lambda:path/2015-03-31/functions/LAMBDA\_ARN/invocations).<br/>When var.authorizer is provided, it is automatically assigned to methods with authorization="CUSTOM" that have no explicit authorizer\_id. | <pre>object({<br/>    type                             = optional(string, "TOKEN") // TOKEN or REQUEST<br/>    identity_source                  = optional(string, "method.request.header.Authorization")<br/>    authorizer_uri                   = string<br/>    authorizer_credentials           = optional(string)<br/>    authorizer_result_ttl_in_seconds = optional(number, 300)<br/>    identity_validation_expression   = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_cloudwatch_attach_policy_inline"></a> [cloudwatch\_attach\_policy\_inline](#input\_cloudwatch\_attach\_policy\_inline) | When set to true, CloudWatch logging permissions are attached as an inline role policy instead of a standalone managed policy. Use this when your environment restricts creation of IAM managed policies. | `bool` | `false` | no |
| <a name="input_cloudwatch_role_name"></a> [cloudwatch\_role\_name](#input\_cloudwatch\_role\_name) | Name for the API Gateway CloudWatch role. Only change if you need a custom name. Default is 'BURoleForAPIGatewayCloudwatchGlobal'. | `string` | `"BURoleForAPIGatewayCloudwatchGlobal"` | no |
| <a name="input_create_cloudwatch_role"></a> [create\_cloudwatch\_role](#input\_create\_cloudwatch\_role) | Whether this module creates the API Gateway CloudWatch role. If false, a role matching 'cloudwatch\_role\_name' must already exist. | `bool` | `true` | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | Domain name attributes. Provide either 'certificate\_arn' or both 'certificate\_body' and 'private\_key'. If providing the 'certificate\_body' and 'private\_key', this must be as a file location | <pre>object({<br/>    domain_name      = string<br/>    certificate_arn  = optional(string)<br/>    certificate_body = optional(string)<br/>    private_key      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | Definition of the API deployment and stage | <pre>object({<br/>    description = optional(string)<br/>    triggers    = optional(map(string))<br/>    variables   = optional(map(string))<br/>    stage = object({<br/>      stage_name                 = string<br/>      description                = optional(string)<br/>      cache_cluster_enabled      = optional(bool, false)<br/>      cache_cluster_size         = optional(string, "0.5")<br/>      variables                  = optional(map(string))<br/>      xray_tracing_enabled       = optional(bool, false)<br/>      access_log_destination_arn = optional(string)<br/>      access_log_format          = optional(string)<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_document_version"></a> [document\_version](#input\_document\_version) | API Gateway documentation version | <pre>object({<br/>    version     = string<br/>    description = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_documentation_parts"></a> [documentation\_parts](#input\_documentation\_parts) | List of API Gateway documentation parts | <pre>list(object({<br/>    location = object({<br/>      method      = optional(string)<br/>      name        = optional(string)<br/>      path        = optional(string)<br/>      status_code = optional(string)<br/>      type        = string<br/>    })<br/>    properties = string<br/>  }))</pre> | `[]` | no |
| <a name="input_external_eec_endpoints"></a> [external\_eec\_endpoints](#input\_external\_eec\_endpoints) | Enable external EEC endpoints, defaults to false. Option ignored if providing own endpoint ID. | `bool` | `false` | no |
| <a name="input_gateway_response"></a> [gateway\_response](#input\_gateway\_response) | List of API Gateway gateway responses | <pre>object({<br/>    response_type       = string<br/>    status_code         = optional(string)<br/>    response_parameters = optional(map(string))<br/>    response_templates  = optional(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_method_settings"></a> [method\_settings](#input\_method\_settings) | Settings for all methods | <pre>object({<br/>    metrics_enabled                            = optional(bool, true)<br/>    logging_level                              = optional(string, "INFO")<br/>    data_trace_enabled                         = optional(bool, false)<br/>    throttling_burst_limit                     = optional(number, -1)<br/>    throttling_rate_limit                      = optional(number, -1)<br/>    caching_enabled                            = optional(bool, true)<br/>    cache_ttl_in_seconds                       = optional(number, 300)<br/>    cache_data_encrypted                       = optional(bool, true)<br/>    require_authorization_for_cache_control    = optional(bool, true)<br/>    unauthorized_cache_control_header_strategy = optional(string, "FAIL_WITH_403")<br/>  })</pre> | `{}` | no |
| <a name="input_models"></a> [models](#input\_models) | API Gateway models | <pre>list(object({<br/>    name         = string<br/>    description  = optional(string)<br/>    content_type = string<br/>    schema       = string<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the API Gateway | `string` | n/a | yes |
| <a name="input_open_api_json"></a> [open\_api\_json](#input\_open\_api\_json) | OpenAPI/Swagger JSON specification for the API Gateway | `string` | `null` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | ARN of the IAM policy to use as a permissions boundary for the CloudWatch IAM role. If not set, no permissions boundary is applied. | `string` | `null` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | List of API Gateway resources | <pre>map(object({<br/>    is_well_known = optional(bool, false)<br/>    methods = map(object({<br/>      authorization      = string<br/>      authorizer_id      = optional(string)<br/>      operation_name     = optional(string)<br/>      request_models     = optional(map(string))<br/>      request_parameters = optional(map(string))<br/>      request_validator  = optional(string)<br/>      method_responses = optional(list(object({<br/>        status_code         = string<br/>        response_models     = optional(map(string))<br/>        response_parameters = optional(map(string))<br/>      })))<br/>      integration = object({<br/>        integration_method     = optional(string)<br/>        type                   = string<br/>        connection_type        = optional(string, "INTERNET")<br/>        uri                    = optional(string)<br/>        credentials            = optional(string)<br/>        request_templates      = optional(map(string))<br/>        request_parameters     = optional(map(string))<br/>        passthrough_behavior   = optional(string)<br/>        cache_key_parameters   = optional(list(string))<br/>        cache_namespace        = optional(string)<br/>        content_handling       = optional(string)<br/>        timeout_milliseconds   = optional(number, 29000)<br/>        integration_target     = optional(string)<br/>        response_transfer_mode = optional(string, "BUFFERED")<br/>      })<br/>      integration_responses = optional(list(object({<br/>        status_code         = string<br/>        content_handling    = optional(string)<br/>        response_parameters = optional(map(string))<br/>        response_templates  = optional(map(string))<br/>        selection_pattern   = optional(string)<br/>      })))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource tags, see https://pages.experian.local/spaces/SC/pages/400041906/Cloud+Tagging+Strategy+Standards | `map(string)` | `{}` | no |
| <a name="input_usage_plan"></a> [usage\_plan](#input\_usage\_plan) | Usage plan settings for the stage | <pre>object({<br/>    description  = optional(string)<br/>    product_code = optional(string)<br/>    stage_throttles = optional(list(object({<br/>      path        = string<br/>      burst_limit = optional(number, -1)<br/>      rate_limit  = optional(number, -1)<br/>    })), [])<br/>    quota_settings = optional(object({<br/>      limit  = optional(number, -1)<br/>      offset = optional(number, 0)<br/>      period = optional(string, "DAY")<br/>    }))<br/>    throttle_settings = optional(object({<br/>      burst_limit = optional(number, -1)<br/>      rate_limit  = optional(number, -1)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_validators"></a> [validators](#input\_validators) | List of named validators | <pre>list(object({<br/>    name                        = string<br/>    validate_request_body       = optional(bool, false)<br/>    validate_request_parameters = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | List of API endpoint IDs. Defaults to regional EEC endpoints | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_arn"></a> [acm\_arn](#output\_acm\_arn) | The ARN of the ACM certificate associated with the custom domain |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the API Gateway REST API |
| <a name="output_authorizer_id"></a> [authorizer\_id](#output\_authorizer\_id) | The ID of the API Gateway authorizer (if created) |
| <a name="output_id"></a> [id](#output\_id) | The ID of the API Gateway REST API |
| <a name="output_invoke_url"></a> [invoke\_url](#output\_invoke\_url) | The invoke URL of the API Gateway REST API |
| <a name="output_root_resource_id"></a> [root\_resource\_id](#output\_root\_resource\_id) | The root resource ID of the API Gateway REST API |
<!-- END_TF_DOCS -->

## Metadata

```discoveryhub
summary: Terraform module for AWS API Gateway
region: Global
bu: EITS
docs: https://experian.atlassian.net/wiki/x/HQ4EF
contacts:
  technical: EITS UK&I Cloud Enablement Team <eitsukicloud@experian.com>
```

[AWS specific extensions]: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html
[OpenAPI/Swagger]: https://spec.openapis.org/oas/v3.0.4.html
[E-Connect (v3) AWS CSSv3 -  VPC EndPoints]: https://pages.experian.local/spaces/SC/pages/1273203644/E-Connect+v3+-+CSSv3+-+AWS+VPC+EndPoints
[Internal connectivity]: https://pages.experian.local/spaces/SC/pages/1524854234/How+To+Configure+an+API+Gateway+backend+service+for+internal+connectivity
