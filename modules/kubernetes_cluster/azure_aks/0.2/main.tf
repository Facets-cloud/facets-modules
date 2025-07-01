module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

module "k8s_cluster" {
  source        = "./k8s_cluster"
  instance      = var.instance
  vpc_id        = var.inputs.network_details.attributes.vpc_id
  cc_metadata   = var.cc_metadata
  environment   = var.environment
  cluster       = var.cluster
  k8s_subnets   = var.inputs.network_details.attributes.private_subnet_ids
  instance_name = var.instance_name
  region        = var.inputs.network_details.attributes.region
  azs           = var.inputs.network_details.attributes.availability_zones
  resource_group_name = var.inputs.network_details.attributes.resource_group_name
  public_subnets = var.inputs.network_details.attributes.public_subnet_ids
  private_subnets = var.inputs.network_details.attributes.private_subnet_ids

}

# Storage class for AKS
module "storage_class" {
  depends_on      = [module.k8s_cluster]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "aks-storage-class"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-storage-class"
  data            = local.storage_class_data
  advanced_config = {}
}

# Default node pool reference (for compatibility)
module "default_node_pool" {
  depends_on      = [module.k8s_cluster]
  count           = lookup(local.default_node_pool, "enabled", true) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-default-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-default-np"
  data            = local.default_node_pool_data
  advanced_config = {}
}

# Dedicated node pool reference (for compatibility)
module "dedicated_node_pool" {
  depends_on      = [module.k8s_cluster]
  count           = lookup(local.dedicated_node_pool, "enabled", false) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-dedicated-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-dedicated-np"
  data            = local.dedicated_node_pool_data
  advanced_config = {}
}

provider "kubernetes" {
  host                   = module.k8s_cluster.k8s_details.cluster.auth.host
  client_certificate     = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
  client_key             = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
  cluster_ca_certificate = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.k8s_cluster.k8s_details.cluster.auth.host
    client_certificate     = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
    client_key             = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
    cluster_ca_certificate = base64decode(module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate)
  }
}

# Secret copier helm release
resource "helm_release" "secret-copier" {
  depends_on = [module.k8s_cluster]
  count      = lookup(local.secret_copier, "disabled", false) ? 0 : 1
  chart      = lookup(local.secret_copier, "chart", "secret-copier")
  namespace  = lookup(local.secret_copier, "namespace", local.namespace)
  name       = lookup(local.secret_copier, "name", "facets-secret-copier")
  repository = lookup(local.secret_copier, "repository", "https://facets-cloud.github.io/helm-charts")
  version    = lookup(local.secret_copier, "version", "1.0.2")
  
  values = [
    yamlencode(
      {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "300m"
            memory = "1000Mi"
          }
        }
      }
    ),
    yamlencode(local.user_supplied_helm_values)
  ]
}

# Cluster overprovisioner for better resource management
resource "helm_release" "cluster-overprovisioner" {
  depends_on      = [module.k8s_cluster]
  name            = "${local.name}-cluster-overprovisioner"
  repository      = "https://charts.deliveryhero.io/"
  chart           = "cluster-overprovisioner"
  version         = "0.7.10"
  wait            = false
  cleanup_on_fail = true
  
  values = [
    <<DEPLOYMENTS
priorityClassOverprovision:
  name: overprovisioning-apps
  value: 1
priorityClassDefault:
  enabled: true
deployments:
  - name: overprovisioner
    annotations: {}
    replicaCount: ${lookup(local.spec, "overprovisioner_replicas", 1)}
    nodeSelector: {}
    resources:
      requests:
        cpu: 500m
        memory: 500Mi
    tolerations: []
    affinity: {}
    labels: {}
DEPLOYMENTS
  ]
}