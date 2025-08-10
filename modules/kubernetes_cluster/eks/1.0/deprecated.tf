# # Deprecated Kubernetes resources - moved out of module for provider management
# # These resources should be managed externally or via GitOps

# resource "kubernetes_storage_class" "eks-auto-mode-gp3" {
#   count      = 0  # Disabled - manage via GitOps instead
#   depends_on = [module.k8s_cluster]
#   metadata {
#     name = "eks-auto-mode-gp3-sc"
#     annotations = {
#       "storageclass.kubernetes.io/is-default-class" = "true"
#     }
#   }
#   storage_provisioner = "ebs.csi.eks.amazonaws.com"
#   reclaim_policy      = local.default_reclaim_policy
#   parameters = {
#     type      = "gp3"
#     encrypted = "true"
#   }
#   allow_volume_expansion = true
#   volume_binding_mode    = "Immediate"
# }

# resource "helm_release" "secret-copier" {
#   count      = 0  # Disabled - manage via GitOps instead
#   depends_on = [module.k8s_cluster]
#   chart      = lookup(local.secret_copier, "chart", "secret-copier")
#   namespace  = lookup(local.secret_copier, "namespace", local.namespace)
#   name       = lookup(local.secret_copier, "name", "facets-secret-copier")
#   repository = lookup(local.secret_copier, "repository", "https://facets-cloud.github.io/helm-charts")
#   version    = lookup(local.secret_copier, "version", "1.0.2")
#   values = [
#     yamlencode({
#       resources = {
#         requests = {
#           cpu    = "50m"
#           memory = "256Mi"
#         }
#         limits = {
#           cpu    = "300m"
#           memory = "1000Mi"
#         }
#       }
#     }),
#     yamlencode(local.user_supplied_helm_values)
#   ]
# }
#
# module "alb" {
#   depends_on      = [module.k8s_cluster]
#   source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
#   name            = "alb"
#   namespace       = var.environment.namespace
#   release_name    = "${local.name}-fc-alb"
#   data            = local.alb_data
#   advanced_config = {}
# }

# module "ingress_class" {
#   depends_on      = [module.alb]
#   source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
#   name            = "alb"
#   namespace       = var.environment.namespace
#   release_name    = "${local.name}-fc-alb-ig-class"
#   advanced_config = {}
#   data            = local.ingress_class_data
# }
