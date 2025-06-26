# Define your locals here
locals {
  tenant_provider           = lower(try(var.cc_metadata.cc_tenant_provider, "aws"))
  spec                      = lookup(var.instance, "spec", {})
  user_supplied_helm_values = try(local.spec.cert_manager.values, try(var.instance.advanced.cert_manager.values, {}))
  cert_manager              = lookup(local.spec, "cert_manager", try(var.instance.advanced.cert_manager, {}))
  cert_mgr_namespace        = "cert-manager"
  advanced                  = lookup(lookup(var.instance, "advanced", {}), "cert_manager", {})
  cnameStrategy             = lookup(local.spec, "cname_strategy", "Follow")
  disable_dns_validation    = lookup(local.spec, "disable_dns_validation", lookup(local.advanced, "disable_dns_validation", false))
  user_defined_tags         = try(local.cert_manager.tags, {})
  deploy_aws_resources      = local.tenant_provider == "aws" ? local.disable_dns_validation ? false : true : false
  dns_providers = {
    aws = {
      route53 = {
        region = try(var.cc_metadata.cc_region, null)
        accessKeyIDSecretRef = {
          key  = "access-key-id"
          name = local.disable_dns_validation ? "na" : kubernetes_secret.cert_manager_r53_secret[0].metadata[0].name
        }
        secretAccessKeySecretRef = {
          key  = "secret-access-key"
          name = local.disable_dns_validation ? "na" : kubernetes_secret.cert_manager_r53_secret[0].metadata[0].name
        }
      }
    }
    google = {
      cloudDNS = {
        project = lookup(try(data.kubernetes_secret_v1.dns[0].data, {}), "project", "")
        serviceAccountSecretRef = {
          key  = "credentials.json"
          name = local.disable_dns_validation ? "na" : kubernetes_secret.cert_manager_r53_secret[0].metadata[0].name
        }
      }
    }
  }
  dns01_validations = {
    staging = {
      name = "letsencrypt-staging"
      url  = "https://acme-staging-v02.api.letsencrypt.org/directory"
      solvers = [
        {
          dns01 = merge({
            cnameStrategy = "Follow"
          }, lookup(local.dns_providers, local.tenant_provider, {}))
        },
      ]
    }
    production = {
      name = "letsencrypt-prod"
      url  = "https://acme-v02.api.letsencrypt.org/directory"
      solvers = [
        {
          dns01 = merge({
            cnameStrategy = "Follow"
          }, lookup(local.dns_providers, local.tenant_provider, {}))
        },
      ]
    }
  }
  http_validations = {
    staging-http01 = {
      name = "letsencrypt-staging-http01"
      url  = "https://acme-staging-v02.api.letsencrypt.org/directory"
      solvers = [
        {
          http01 = {
            ingress = {
              podTemplate = {
                spec = {
                  nodeSelector = local.nodepool_labels
                  tolerations  = local.nodepool_tolerations
                }
              }
            }
          }
        },
      ]
    }
    production-http01 = {
      name = "letsencrypt-prod-http01"
      url  = "https://acme-v02.api.letsencrypt.org/directory"
      solvers = [
        {
          http01 = {
            ingress = {
              podTemplate = {
                spec = {
                  nodeSelector = local.nodepool_labels
                  tolerations  = local.nodepool_tolerations
                }
              }
            }
          }
        },
      ]
    }
  }
  environments = merge(local.http_validations, local.disable_dns_validation ? {} : local.dns01_validations)

  # Nodepool configuration from inputs
  nodepool_config = lookup(var.inputs, "kubernetes_node_pool_details", null) != null ? var.inputs.kubernetes_node_pool_details.attributes : {
    node_class_name = ""
    node_pool_name  = ""
    taints          = []
    node_selector   = {}
  }
  nodepool_tolerations = lookup(local.nodepool_config, "taints", [])
  nodepool_labels      = lookup(local.nodepool_config, "node_selector", {})

  # Use only nodepool configuration (no fallback to default tolerations)
  tolerations  = local.nodepool_tolerations
  nodeSelector = local.nodepool_labels

  # GTS and ACME configuration
  use_gts         = lookup(local.spec, "use_gts", false)
  gts_private_key = lookup(local.spec, "gts_private_key", "")
  acme_email      = lookup(local.spec, "acme_email", "") != "" ? lookup(local.spec, "acme_email", "") : try(var.cluster.createdBy, null)
}

data "kubernetes_secret_v1" "dns" {
  count = local.tenant_provider == "aws" ? 0 : 1
  metadata {
    name      = "facets-tenant-dns"
    namespace = "default"
  }
  provider = "kubernetes.release-pod"
}
