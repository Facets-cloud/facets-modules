terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.tooling]
    }
  }
  required_version = ">= 1.0"
}
