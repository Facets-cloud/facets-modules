terraform {
  required_providers {
    helm3 = {
      source  = "hashicorp/helm3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  required_version = ">= 0.13"
}


