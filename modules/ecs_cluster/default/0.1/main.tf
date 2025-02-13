locals {
  test = true
  metadata  = lookup(var.instance, "metadata", {})
  tags      = merge(var.environment.cloud_tags, lookup(local.metadata, "tags", {}))
  spec      = lookup(var.instance, "spec", {})
  cluster   = lookup(local.spec, "cluster", {})
  lifecycle = upper(lookup(local.cluster, "lifecycle", "spot"))
  fargate_capacity_providers = local.lifecycle == "SPOT" ? {
    FARGATE_SPOT = {
      name = "FARGATE_SPOT"
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
    } : {
    FARGATE = {
      name = "FARGATE"
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 255
  resource_name   = var.instance_name
  resource_type   = "container_service"
  globally_unique = true
  is_k8s          = false
}

module "ecs" {
  source                                  = "./terraform-aws-ecs/modules/cluster"
  autoscaling_capacity_providers          = {}
  cloudwatch_log_group_kms_key_id         = lookup(local.spec, "cloudwatch_log_group_kms_key_id", null)
  cloudwatch_log_group_name               = lookup(local.spec, "cloudwatch_log_group_name", null)
  cloudwatch_log_group_retention_in_days  = lookup(local.spec, "cloudwatch_log_group_retention_in_days", 90)
  cloudwatch_log_group_tags               = local.tags
  cluster_configuration                   = lookup(local.spec, "cluster_configuration", {})
  cluster_name                            = lookup(local.metadata, "name", module.name.name)
  cluster_service_connect_defaults        = lookup(local.spec, "cluster_service_connect_defaults", {})
  cluster_settings                        = lookup(local.spec, "cluster_settings", [])
  create                                  = true
  create_cloudwatch_log_group             = lookup(local.spec, "create_cloudwatch_log_group", false)
  create_task_exec_iam_role               = false
  create_task_exec_policy                 = false
  default_capacity_provider_use_fargate   = true
  fargate_capacity_providers              = local.fargate_capacity_providers
  tags                                    = local.tags
  task_exec_iam_role_description          = ""
  task_exec_iam_role_name                 = module.name.name
  task_exec_iam_role_path                 = null
  task_exec_iam_role_permissions_boundary = null
  task_exec_iam_role_policies             = {}
  task_exec_iam_role_tags                 = local.tags
  task_exec_iam_role_use_name_prefix      = true
  task_exec_secret_arns                   = []
  task_exec_ssm_param_arns                = []
}