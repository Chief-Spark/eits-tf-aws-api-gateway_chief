data "aws_iam_policy_document" "default" {
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current_region.region}:${data.aws_caller_identity.current.account_id}:*/*/*/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
  statement {
    effect    = "Deny"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current_region.region}:${data.aws_caller_identity.current.account_id}:*/*/*/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "StringNotEquals"
      values   = local.vpc_endpoints
      variable = "aws:SourceVpce"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current_region" {}

data "aws_iam_roles" "cloudwatch_role" {
  name_regex = "^${var.cloudwatch_role_name}$"
}

data "aws_default_tags" "current" {}
