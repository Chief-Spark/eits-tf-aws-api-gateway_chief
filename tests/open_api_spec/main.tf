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

  name                   = "example"
  external_eec_endpoints = true
  open_api_json = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
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

  tags = var.tags
}