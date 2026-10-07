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

  name                 = "example-streaming"
  cloudwatch_role_name = "test-streaming-api-role"
  deployment = {
    stage = {
      stage_name  = "streaming-stage"
      description = "Streaming Integration Stage"
    }
  }
  resources = {
    stream_path = {
      methods = {
        get = {
          authorization = "NONE"
          integration = {
            type                   = "HTTP_PROXY"
            uri                    = "https://example.com/api"
            integration_method     = "GET"
            response_transfer_mode = "STREAM"
          }
        }
        post = {
          authorization = "NONE"
          integration = {
            type                   = "HTTP_PROXY"
            uri                    = "https://example.com/api"
            integration_method     = "POST"
            response_transfer_mode = "STREAM"
          }
        }
      }
    }
  }

  tags = var.tags
}
