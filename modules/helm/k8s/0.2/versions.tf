terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  required_version = ">= 0.13"
}
