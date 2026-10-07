resource "aws_api_gateway_account" "global_settings" {
  cloudwatch_role_arn = var.create_cloudwatch_role ? module.cloudwatch_role[0].role_arn : one(data.aws_iam_roles.cloudwatch_role.arns)

  lifecycle {
    precondition {
      condition     = var.create_cloudwatch_role || local.cloudwatch_role_exists
      error_message = "create_cloudwatch_role is false, but no existing CloudWatch role named ${var.cloudwatch_role_name} was found. Either create the role first or set create_cloudwatch_role to true."
    }
  }
}

module "cloudwatch_role" {
  count = var.create_cloudwatch_role ? 1 : 0

  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-iam.git?ref=1.9.7"

  override_role_name   = true
  role_name            = var.cloudwatch_role_name
  policy_name          = "default"
  policy_description   = ""
  policy_documents     = var.cloudwatch_attach_policy_inline ? [] : [data.aws_iam_policy_document.cloudwatch_role[0].json]
  trusted_service      = "apigateway"
  permissions_boundary = var.permissions_boundary

  tags = local.tags
}

data "aws_iam_policy_document" "cloudwatch_role" {
  count = var.create_cloudwatch_role ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch_inline" {
  count = var.create_cloudwatch_role && var.cloudwatch_attach_policy_inline ? 1 : 0

  name   = "BUPolicyForCloudwatchDefault"
  role   = module.cloudwatch_role[0].role_name
  policy = data.aws_iam_policy_document.cloudwatch_role[0].json
}

