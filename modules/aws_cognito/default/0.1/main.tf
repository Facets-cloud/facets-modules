module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  resource_name   = var.instance_name
  resource_type   = "waf"
  globally_unique = false
  is_k8s          = false
}


module "aws-cognito" {
  source = "./terraform-aws-cognito-user-pool-0.33.0"

  
}
