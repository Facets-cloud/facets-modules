locals {
  name    = module.name.name
  spec    = lookup(var.instance, "spec", {})
  cluster = lookup(local.spec, "cluster", {})
  # Commented out - used by deprecated resources
  # default_reclaim_policy    = lookup(local.cluster, "default_reclaim_policy", "Delete")
  # namespace                 = lookup(var.cluster, "namespace", "default")
  # user_supplied_helm_values = lookup(local.secret_copier, "values", {})
  # secret_copier             = lookup(local.spec, "secret-copier", {})
  cloud_tags = var.environment.cloud_tags
  # Commented out - used by deprecated ALB resources
  # alb_data = {
  #   apiVersion = "eks.amazonaws.com/v1"
  #   kind       = "IngressClassParams"
  #   metadata = {
  #     name = "alb"
  #   }
  #   spec = {
  #     tags = [for key, value in local.cloud_tags : { key = key, value = value }]
  #   }
  # }
  # ingress_class_data = {
  #   apiVersion = "networking.k8s.io/v1"
  #   kind       = "IngressClass"
  #   metadata = {
  #     name = "alb"
  #     annotations = {
  #       "ingressclass.kubernetes.io/is-default-class" = "true"
  #     }
  #   }
  #   spec = {
  #     controller = "eks.amazonaws.com/alb"
  #     parameters = {
  #       apiGroup = "eks.amazonaws.com"
  #       kind     = "IngressClassParams"
  #       name     = "alb"
  #     }
  #   }
  # }
}
