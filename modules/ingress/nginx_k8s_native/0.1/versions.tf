terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    acme = {
      source = "vancluever/acme"
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.tooling]
    }
  }
  required_version = ">= 1.0"
}
