locals {
  definition_object = jsondecode(file("test.json"))
}

module "tested" {
  source        = "../"
  instance      = local.definition_object
  instance_name = "test-user"

  environment = {
    namespace   = "default"
    unique_name = "mongo"
  }
}

output "username" {
  value     = module.tested.username
  sensitive = true
}

output "password" {
  value     = module.tested.password
  sensitive = true
}

provider "kubernetes" {
  config_path = ""
}

provider "helm" {
  kubernetes {
    config_path = ""
  }
}
