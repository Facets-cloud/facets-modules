module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_region" "current" {}

# aws_eks_cluster_auth data source removed - not needed with exec plugin


module "eks" {
  source                                   = "./aws-terraform-eks"
  cluster_name                             = module.name.name
  cluster_compute_config                   = local.cluster_compute_config
  cluster_version                          = local.kubernetes_version
  cluster_endpoint_public_access           = local.cluster_endpoint_public_access
  cluster_endpoint_private_access          = local.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs     = local.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = true
  cluster_enabled_log_types                = local.cluster_enabled_log_types
  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.k8s_subnets
  cluster_security_group_additional_rules  = local.cluster_security_group_additional_rules
  cloudwatch_log_group_retention_in_days   = local.cloudwatch_log_group_retention_in_days
  cluster_service_ipv4_cidr                = local.cluster_service_ipv4_cidr
  tags                                     = local.tags
}


resource "aws_eks_addon" "addon" {
  for_each                 = local.addons
  cluster_name             = module.eks.cluster_name
  addon_name               = each.key
  addon_version            = each.value["addon_version"]
  configuration_values     = each.value["configuration_values"]
  resolve_conflicts_on_create = each.value["resolve_conflicts_on_create"]
  resolve_conflicts_on_update = each.value["resolve_conflicts_on_update"]
  tags                     = each.value["tags"]
  preserve                 = each.value["preserve"]
  service_account_role_arn = each.value["service_account_role_arn"]

  lifecycle {
    prevent_destroy = true
  }
}


# These providers need to be force replaced with empty object blocks to prevent Terraform from using default providers
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

# Kubernetes provider removed - configure at consumer level with exec plugin

# Helm provider removed - configure at consumer level with exec plugin
