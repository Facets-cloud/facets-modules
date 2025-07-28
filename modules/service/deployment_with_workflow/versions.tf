terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
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