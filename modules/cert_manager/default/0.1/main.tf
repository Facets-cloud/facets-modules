# Define your terraform resources here
module "iam_user_name" {
  count           = local.disable_dns_validation ? 0 : 1
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  globally_unique = false
  resource_name   = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name
  resource_type   = ""
  is_k8s          = false
}

module "iam_policy_name" {
  count           = local.disable_dns_validation ? 0 : 1
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 128
  globally_unique = false
  resource_name   = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name
  resource_type   = ""
  is_k8s          = false
}

resource "aws_iam_user" "cert_manager_iam_user" {
  count    = local.deploy_aws_resources ? 1 : 0
  provider = "aws.tooling"
  name     = lower(module.iam_user_name[0].name)
  tags     = merge(local.user_defined_tags, var.environment.cloud_tags)
}

resource "aws_iam_user_policy" "cert_manager_r53_policy" {
  count    = local.deploy_aws_resources ? 1 : 0
  provider = "aws.tooling"
  name     = lower(module.iam_policy_name[0].name)
  user     = try(aws_iam_user.cert_manager_iam_user[0].name, "na")
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${try(var.cc_metadata.tenant_base_domain_id, "*")}"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "cert_manager_access_key" {
  count    = local.deploy_aws_resources ? 1 : 0
  provider = "aws.tooling"
  user     = try(aws_iam_user.cert_manager_iam_user[0].name, "na")
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.cert_mgr_namespace
  }
}

resource "kubernetes_secret" "cert_manager_r53_secret" {
  count      = local.disable_dns_validation ? 0 : 1
  depends_on = [kubernetes_namespace.namespace]
  metadata {
    name      = "${lower(module.iam_user_name[0].name)}-secret"
    namespace = local.cert_mgr_namespace
  }
  data = jsondecode(local.tenant_provider == "aws" ? jsonencode({
    "access-key-id"     = aws_iam_access_key.cert_manager_access_key[0].id
    "secret-access-key" = aws_iam_access_key.cert_manager_access_key[0].secret
    }) : jsonencode({
    "credentials.json" = lookup(lookup(try(data.kubernetes_secret_v1.dns[0], {}), "data", {}), "credentials.json", "{}")
  }))
}

resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.namespace]
  name       = "cert-manager"
  # repository       = "https://charts.jetstack.io"
  chart            = "${path.module}/cert-manager-v1.17.1.tgz"
  namespace        = local.cert_mgr_namespace
  create_namespace = false
  # version          = lookup(local.cert_manager, "version", "1.13.3")
  cleanup_on_fail = lookup(local.cert_manager, "cleanup_on_fail", true)
  wait            = lookup(local.cert_manager, "wait", true)
  atomic          = lookup(local.cert_manager, "atomic", false)
  timeout         = lookup(local.cert_manager, "timeout", 600)
  recreate_pods   = lookup(local.cert_manager, "recreate_pods", false)

  set {
    name  = "installCRDs"
    value = true
  }

  values = [
    <<EOF
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
EOF
    , yamlencode({
      nodeSelector = local.nodeSelector
      tolerations  = local.tolerations
      replicaCount = 2

      webhook = {
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
        replicaCount = 3
      }
      cainjector = {
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
      }
      startupapicheck = {
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
      }
      prometheus = {
        enabled = true
        servicemonitor = {
          enabled = true
        }
      }
    }),
    yamlencode(local.user_supplied_helm_values),
  ]

}

module "cluster-issuer" {
  depends_on = [helm_release.cert_manager]
  for_each   = local.use_gts ? {} : local.environments

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = each.value.name
  namespace       = local.cert_mgr_namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = each.value.name
    }
    spec = {
      acme = {
        email  = local.acme_email
        server = each.value.url
        privateKeySecretRef = {
          name = "letsencrypt-${each.key}-account-key"
        }
        solvers = each.value.solvers
      }
    }
  }

}


resource "kubernetes_secret" "google-trust-services-prod-account-key" {
  count      = local.use_gts ? 1 : 0
  depends_on = [kubernetes_namespace.namespace]
  metadata {
    name      = "google-trust-services-prod-account-key"
    namespace = local.cert_mgr_namespace
  }
  data = {
    "tls.key" = local.gts_private_key
  }
}

module "cluster-issuer-gts-prod" {
  count           = local.use_gts ? 1 : 0
  depends_on      = [helm_release.cert_manager]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "gts-production"
  namespace       = local.cert_mgr_namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "gts-production"
    }
    spec = {
      acme = {
        email                       = local.acme_email
        server                      = local.use_gts ? "https://dv.acme-v02.api.pki.goog/directory" : "https://acme-v02.api.letsencrypt.org/directory"
        disableAccountKeyGeneration = true
        privateKeySecretRef = {
          name = kubernetes_secret.google-trust-services-prod-account-key[0].metadata[0].name
        }
        solvers = [
          {
            dns01 = merge({
              cnameStrategy = local.cnameStrategy
            }, lookup(local.dns_providers, local.tenant_provider, {}))
          },
        ]
      }
    }
  }

}


module "cluster-issuer-gts-prod-http01" {
  count           = local.use_gts ? 1 : 0
  depends_on      = [helm_release.cert_manager]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "gts-production-http01"
  namespace       = local.cert_mgr_namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "gts-production-http01"
    }
    spec = {
      acme = {
        email                       = local.acme_email
        server                      = local.use_gts ? "https://dv.acme-v02.api.pki.goog/directory" : "https://acme-v02.api.letsencrypt.org/directory"
        disableAccountKeyGeneration = true
        privateKeySecretRef = {
          name = kubernetes_secret.google-trust-services-prod-account-key[0].metadata[0].name
        }
        solvers = [
          {
            http01 = {
              ingress = {
                podTemplate = {
                  spec = {
                    nodeSelector = local.nodeSelector
                    tolerations  = local.tolerations
                  }
                }
              }
            }
          },
        ]
      }
    }
  }

}
