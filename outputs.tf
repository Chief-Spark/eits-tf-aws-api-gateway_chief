output "arn" {
  description = "The ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.arn
}

output "id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  description = "The invoke URL of the API Gateway REST API"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "acm_arn" {
  description = "The ARN of the ACM certificate associated with the custom domain"
  value       = coalesce(try(module.acm.arn, null), try(var.custom_domain_name.certificate_arn, null), "NA")
}

output "root_resource_id" {
  description = "The root resource ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

output "authorizer_id" {
  description = "The ID of the API Gateway authorizer (if created)"
  value       = try(aws_api_gateway_authorizer.this[0].id, null)
}
