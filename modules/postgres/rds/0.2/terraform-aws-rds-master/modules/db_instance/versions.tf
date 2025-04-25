terraform {
  required_version = ">= 1.0"

  required_providers {
    aws5 = {
      source = "hashicorp/aws5"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
