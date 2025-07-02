locals {
  deploy_context    = jsondecode(file("../deploymentcontext.json"))
  dep_cluster       = lookup(local.deploy_context, "cluster", {})
  image_id          = lookup(local.release, "image", "NOT_FOUND")
  metadata        = lookup(var.instance, "metadata", {})
  tags            = merge(var.environment.cloud_tags, lookup(local.metadata, "tags", {}))
  spec                    = lookup(var.instance, "spec", {})
  readonly_root_filesystem = lookup(local.runtime, "readonly_root_filesystem", true)
  runtime         = lookup(local.spec, "runtime", {})
  release         = lookup(local.spec, "release", {})
  advanced        = lookup(var.instance, "advanced", {})
  advanced_ecs    = lookup(local.advanced, "aws_ecs", {})
  advanced_lb     = lookup(local.advanced, "aws_alb", {})
  advanced_common = lookup(local.advanced, "common", {})
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }
  deployment_id = lookup(local.advanced_common, "pass_deployment_id", false) ? var.environment.deployment_id : ""
  env_vars = merge(lookup(local.dep_cluster, "globalVariables", {}),
    lookup(local.advanced_common, "include_common_env_variables", false) ? var.environment.common_environment_variables : {}, lookup(local.spec, "env", {}),
    length(local.deployment_id) > 0 ? {
      deployment_id = local.deployment_id
    } : {}
  )
  secrets = [for key, value in local.env_vars :
    {
      name      = key
      valueFrom = "${module.secrets.attributes.secret_arn}:${key}::"
    }
  ]
  container_definitions = {
    service = {
      name  = var.instance_name
      image = local.image_id
      port_mappings = [for key, value in lookup(local.runtime, "ports", {}) : {
        containerPort = tonumber(value.port)
        hostPort      = tonumber(lookup(value, "service_port", value.port))
        protocol      = value.protocol
      }]
      cpu       = lookup(lookup(local.runtime, "size", {}), "cpu", null)
      memory    = lookup(lookup(local.runtime, "size", {}), "memory", null) * 1024
      essential = lookup(local.advanced_ecs, "essential", true)
      command   = concat(
        lookup(local.runtime, "command", null) == null ? [] : [lookup(local.runtime, "command", null)],
        [for key, value in lookup(local.runtime, "args", {}) : value.argument]
      )
      privileged                = false
      readonly_root_filesystem  = lookup(local.runtime, "readonly_root_filesystem", true)
      enable_cloudwatch_logging = true
      secrets                   = local.secrets
    }
  }
  load_balancers = {}
  aws_cloud_permissions = lookup(lookup(local.spec, "cloud_permissions", {}), "aws", {})
  iam_arns = lookup(local.aws_cloud_permissions, "iam_policies", {})
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 255
  resource_name   = var.instance_name
  resource_type   = "ervice"
  globally_unique = false
  is_k8s          = false
  prefix          = "s"
}

module "iam_role_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  resource_name   = var.instance_name
  resource_type   = "ervice"
  globally_unique = false
  is_k8s          = false
  prefix          = "s"
}

module "secrets" {
  source      = "./aws_secret_manager"
  baseinfra   = var.baseinfra
  cc_metadata = var.cc_metadata
  cluster     = var.cluster
  environment = var.environment
  instance = {
    spec = {
      secrets = local.env_vars
    }
  }
  instance_name             = var.instance_name
  generate_release_metadata = false
}

module "ecs" {
  source                             = "./terraform-aws-ecs/modules/service"
  alarms                             = lookup(local.advanced_ecs, "alarms", {})
  assign_public_ip                   = lookup(local.advanced_ecs, "assign_public_ip", false)
  autoscaling_max_capacity           = lookup(lookup(local.runtime, "autoscaling", {}), "max", 1)
  autoscaling_min_capacity           = lookup(lookup(local.runtime, "autoscaling", {}), "min", 1)
  autoscaling_policies               = lookup(local.advanced_ecs, "autoscaling_policies", local.autoscaling_policies)
  autoscaling_scheduled_actions      = lookup(local.advanced_ecs, "autoscaling_scheduled_actions", {})
  capacity_provider_strategy         = lookup(local.advanced_ecs, "capacity_provider_strategy", {})
  cluster_arn                        = var.inputs.ecs_details.attributes.cluster_arn
  container_definition_defaults      = lookup(local.advanced_ecs, "container_definition_defaults", {})
  container_definitions              = local.container_definitions
  cpu                                = tonumber(lookup(lookup(local.runtime, "size", {}), "cpu", null))
  create                             = true
  create_iam_role                    = true
  create_security_group              = true
  create_service                     = true
  create_task_definition             = true
  create_task_exec_iam_role          = true
  create_task_exec_policy            = true
  create_tasks_iam_role              = true
  deployment_circuit_breaker         = lookup(local.advanced_ecs, "deployment_circuit_breaker", {})
  deployment_controller              = lookup(local.advanced_ecs, "deployment_controller", {})
  deployment_maximum_percent         = lookup(local.advanced_ecs, "deployment_maximum_percent", 200)
  deployment_minimum_healthy_percent = lookup(local.advanced_ecs, "deployment_minimum_healthy_percent", 66)
  desired_count                      = lookup(lookup(local.runtime, "autoscaling", {}), "min", 1)
  enable_autoscaling                 = contains(keys(local.runtime), "autoscaling") ? true : false
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  ephemeral_storage                  = lookup(local.advanced_ecs, "ephemeral_storage", {})
  external_id                        = null
  family                             = module.name.name
  force_delete                       = true
  force_new_deployment               = true
  health_check_grace_period_seconds  = null
  iam_role_description               = ""
  iam_role_name                      = module.iam_role_name.name
  iam_role_path                      = lookup(local.advanced_ecs, "iam_role_path", null)
  iam_role_permissions_boundary      = lookup(local.advanced_ecs, "iam_role_permissions_boundary", null)
  iam_role_statements                = {}
  iam_role_tags                      = local.tags
  ignore_task_definition_changes     = lookup(local.advanced_ecs, "ignore_task_definition_changes", false)
  inference_accelerator              = lookup(local.advanced_ecs, "inference_accelerator", {})
  ipc_mode                           = lookup(local.advanced_ecs, "ipc_mode", null)
  launch_type                        = "FARGATE"
  load_balancer                      = local.load_balancers
  memory                             = tonumber(lookup(lookup(local.runtime, "size", {}), "memory", null)) * 1024
  name                               = module.name.name
  network_mode                       = lookup(local.advanced_ecs, "network_mode", "awsvpc")
  ordered_placement_strategy         = lookup(local.advanced_ecs, "ordered_placement_strategy", {})
  pid_mode                           = lookup(local.advanced_ecs, "pid_mode", null)
  placement_constraints              = lookup(local.advanced_ecs, "placement_constraints", {})
  platform_version                   = lookup(local.advanced_ecs, "platform_version", null)
  propagate_tags                     = "SERVICE"
  proxy_configuration                = {}
  requires_compatibilities           = ["FARGATE"]
  runtime_platform                   = lookup(local.advanced_ecs, "runtime_platform", { "cpu_architecture" : "X86_64", "operating_system_family" : "LINUX" })
  scale                              = lookup(local.advanced_ecs, "scale", {})
  scheduling_strategy                = lookup(local.advanced_ecs, "scheduling_strategy", null)
  security_group_description         = "Security group created through terraform for ECS ${module.name.name}"
  security_group_name                = module.name.name
  security_group_rules = {
    all_outbound_traffic = {
      type        = "egress"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allowing all outbound traffic, withing the VPC."
    }
    vpc_inbound_traffic = {
      type        = "ingress"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = [var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr]
      description = "Allowing all inbound traffic, within the VPC."
    }
  }
  security_group_tags                     = local.tags
  service_connect_configuration           = lookup(local.advanced_ecs, "service_connect_configuration", {})
  service_registries                      = lookup(local.advanced_ecs, "service_registries", {})
  service_tags                            = local.tags
  skip_destroy                            = false
  subnet_ids                              = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnets
  tags                                    = local.tags
  task_definition_arn                     = lookup(local.advanced_ecs, "task_definition_arn", null)
  task_exec_iam_role_description          = "Task Exec role created through terraform for ECS ${module.name.name}"
  task_exec_iam_role_max_session_duration = lookup(local.advanced_ecs, "task_exec_iam_role_max_session_duration", null)
  task_exec_iam_role_name                 = length(module.iam_role_name.name) > 38 ? substr(replace(module.iam_role_name.name, "-", ""), 0, 38) : module.iam_role_name.name
  task_exec_iam_role_path                 = lookup(local.advanced_ecs, "task_exec_iam_role_path", null)
  task_exec_iam_role_permissions_boundary = lookup(local.advanced_ecs, "task_exec_iam_role_permissions_boundary", null)
  task_exec_iam_role_policies             = lookup(local.advanced_ecs, "task_exec_iam_role_policies", {})
  task_exec_iam_role_tags                 = local.tags
  task_exec_iam_statements                = {}
  task_exec_secret_arns                   = lookup(local.advanced_ecs, "task_exec_secret_arns", ["arn:aws:secretsmanager:*:*:secret:*"])
  task_exec_ssm_param_arns                = lookup(local.advanced_ecs, "task_exec_ssm_param_arns", ["arn:aws:ssm:*:*:parameter/*"])
  task_tags                               = local.tags
  tasks_iam_role_description              = "Task created through terraform for ECS ${module.name.name}"
  tasks_iam_role_name                     = module.iam_role_name.name
  tasks_iam_role_path                     = lookup(local.advanced_ecs, "tasks_iam_role_path", null)
  tasks_iam_role_permissions_boundary     = lookup(local.advanced_ecs, "tasks_iam_role_permissions_boundary", null)
  tasks_iam_role_policies                 = merge(
    { "read_only_policy" = module.secrets.attributes.iam_policies.read_only },
    { for k, v in local.iam_arns: k => v.arn }
  )
  tasks_iam_role_statements               = {}
  tasks_iam_role_tags                     = local.tags
  timeouts                                = lookup(local.advanced_ecs, "timeouts", {})
  triggers                                = lookup(local.advanced_ecs, "triggers", {})
  volume                                  = lookup(local.advanced_ecs, "volume", {})
  vpc_id                                  = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  wait_for_steady_state                   = lookup(local.advanced_ecs, "wait_for_steady_state", false)
  wait_until_stable                       = lookup(local.advanced_ecs, "wait_until_stable", false)
  wait_until_stable_timeout               = lookup(local.advanced_ecs, "wait_until_stable_timeout", null)
}

