terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.tooling]
    }
    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.6.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }

  }
  required_version = ">= 0.13"
}
