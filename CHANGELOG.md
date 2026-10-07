# RELEASE NOTES

## 1.4.2 - 14th September 2026

- Updated confluence document links

## 1.4.1 - 16th July 2026

- Dependency update: ACM module to version 2.3.2
- Updated pre-commit config to version 1.4.0

## 1.4.0 - 5th June 2026

### Added
- Added new input variable `cloudwatch_attach_policy_inline` (default: `false`) to attach CloudWatch permissions as an inline policy instead of a managed policy
- Added new input variable `permissions_boundary` (default: `null`) to optionally apply an IAM permissions boundary ARN to created roles
- Added `override_role_name = true` to the CloudWatch role module to enforce the provided role name
- Added `aws_iam_role_policy` resource `cloudwatch_inline` to attach the inline policy when `cloudwatch_attach_policy_inline` is `true` and the role does not already exist
- Added validation for OpenAPI JSON specification in `variables.tf`
- Added new output `authorizer_id` to expose the Lambda authorizer ID (returns `null` if no authorizer is configured)
- Automatic authorizer assignment: when `var.authorizer` is provided, it is automatically applied to all methods with `authorization = "CUSTOM"` that have no explicit `authorizer_id`
- Added `resource_key` field to `locals.methods`, `locals.method_responses`, and `locals.integration_responses` to carry the original map key through computed collections
- Added `depends_on = [aws_api_gateway_account.global_settings]` to `aws_api_gateway_stage` to prevent race conditions when the account-level CloudWatch role is being created in the same apply
- Added `aws_api_gateway_method_response.this` to `aws_api_gateway_deployment` `depends_on` to ensure responses are fully created before deployment

### Changed
- Updated default value of `cloudwatch_role_name` from `"APIGatewayCloudwatchGlobal"` to `"BURoleForAPIGatewayCloudwatchGlobal"` for corporate naming convention consistency (`BURoleFor*`)

### Fixed
- Fixed `data.aws_iam_roles.cloudwatch_role` name regex to use an exact match against `var.cloudwatch_role_name` instead of a hardcoded value
- Fixed `resource_id` lookup in `aws_api_gateway_integration`, `aws_api_gateway_integration_response`, `aws_api_gateway_method`, and `aws_api_gateway_method_response` — previously used `split("-", each.key)[0]` which silently mapped to the wrong resource when the resource key contained a hyphen (e.g. `health-check`)
- Fixed `cloudwatch_role_exists` local to a static `false` to avoid "count value depends on resource attributes that cannot be determined until apply" error
- Fixed "No integration defined for method" deployment errors by relying solely on `var.deployment.triggers` for deployment invalidation — callers should include adapter integration IDs as a hashed key in the triggers map
- Fixed "Invalid authorizer ID specified" errors — authorizer is now auto-assigned via `var.authorizer != null` check directly in `resources.tf`, no extra variable needed

## 1.3.0 - 19th May 2026

- Added `create_cloudwatch_role` to explicitly control CloudWatch role creation.
- Added validation to check when `create_cloudwatch_role = false` and `cloudwatch_role_name` does not exist.

## 1.2.0 - 18th May 2026

- Added `response_transfer_mode` parameter to API Gateway integrations for improved response handling control
- Set default `response_transfer_mode` to `BUFFERED` for consistent buffered response behavior

## 1.1.1 - 7th May 2026

- Updated `eits-tf-aws-acm.git` module to version `2.3.1`
- Updated `eits-tf-aws-iam.git` module to version `1.9.7`
- Updated AWS provider version to `>= 6.25.0`

## 1.1.0 - 17th March 2026

- Added new input variable `cloudwatch_role_name` to allow customization of the API Gateway CloudWatch role name
- `cloudwatch_role_name` defaults to `APIGatewayCloudwatchGlobal`, preserving backward compatibility
- Updated test scenarios to cover the new `cloudwatch_role_name` variable

## 1.0.0 - 27th January 2026

- Initial release
