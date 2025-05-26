terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.tooling]
    }
  }
  required_version = ">= 1.0"
}