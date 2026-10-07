terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "api" {
  source = "./../../"

  name                            = "example-cloudwatch-custom"
  cloudwatch_role_name            = "test-custom-cloudwatch-role"
  cloudwatch_attach_policy_inline = true
  permissions_boundary            = "arn:aws:iam::123456789012:policy/example-permissions-boundary"
  
  deployment = {
    stage = {
      stage_name  = "example-stage"
      description = "Example Stage with Custom CloudWatch Configuration"
    }
  }
  
  resources = {
    test_path = {
      methods = {
        get = {
          authorization = "NONE"
          integration = {
            type = "MOCK"
          }
        }
      }
    }
  }

  tags = var.tags
}
