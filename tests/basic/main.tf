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

  name                 = "example"
  cloudwatch_role_name = "test-example-api-role"
  deployment = {
    stage = {
      stage_name  = "example-stage"
      description = "Example Stage"
    }
  }
  resources = {
    my_app_path_1 = {
      methods = {
        get = {
          authorization = "NONE"
          integration = {
            type                   = "MOCK"
            response_transfer_mode = "BUFFERED"
          }
        }
        post = {
          authorization = "NONE"
          integration = {
            type                   = "MOCK"
            response_transfer_mode = "BUFFERED"
          }
        }
      }
    }
    my_app_path_2 = {
      methods = {
        get = {
          authorization = "NONE"
          integration = {
            type                   = "MOCK"
            response_transfer_mode = "BUFFERED"
          }
        }
        post = {
          authorization = "NONE"
          integration = {
            type                   = "MOCK"
            response_transfer_mode = "BUFFERED"
          }
        }
      }
    }
  }

  tags = var.tags
}