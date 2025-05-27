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
      "Resource": "arn:aws:route53:::hostedzone/${var.cc_metadata.tenant_base_domain_id}"
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
  for_each   = local.environments

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
        email  = "rohit.raveendran@capillarytech.com"
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
  depends_on = [kubernetes_namespace.namespace]
  metadata {
    name      = "google-trust-services-prod-account-key"
    namespace = local.cert_mgr_namespace
  }
  data = {
    "tls.key" : <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAsxnx1TcJw5ZlrJzDHXmIgrQ+vbnJzz4bkgDsDksWvs6eKC3w
wkUbMuoy+2cML3ZAyflQRbfC+ipZXIDS7mTKnxtqzH03xDHQdU1lfo2KWG8ddDCf
QsPCxUUmhhPlmabXMkTlEZMBhLufLIz1ady1o7dNsTIFs+BuTV34sCnmnJEScw5a
CJPUKoLsi36HmywMkCJu3wmfRnUGmhmYAIIFT446T15TTZ8dadcUZZUauL4ilD8H
D5QQ2VfhNamMLTKnMmXtsmaaTh/XhjozOZWv69nubftfxucBwRX5l2oWxa7pNodV
rDeABjMEL5/5pla+wQYSoASGmssDDKAXmMraEQIDAQABAoIBAAb2EPF31mwQ9io3
nJjSbrUf0tl2dWrV7+XkncgvcHahmsGWiYdPfs9jjXA6kN1uY/XFuDJBgnVNPJRt
GGW2Kq709pl0m3yHcCIDDFkXIMOvq+4mbqY+bB1VQvpOnyux8abNSTb95v70+OqX
HvnKn4+5se4bct/LLxZYOvCD7Gf05cFMHc6KCVKrP4Xa4+fj0nx6SE2EMjh1o1qB
FDEIOitKHb0TGSqek+TdRp17e90dZ0eUUTeGEld59ZY6uiHrxG+HuTYMrj+Md84p
E5DNuglprwLA59fLClO9HAy5vjv6WYglFQe8tNdFD61pr5wJ3V6/MrwU5e1GFvvj
ia9yqg0CgYEA85ST19C8dzNxSMZOnuHmc0an3/yXLH3jc5BL3P8XBvzkPM4Kb5UA
SpZbUtqeiXlfbNpi0WsdFu9wl61yzoR2BwZz+PAiDRWkaWaeLzZGJ2TnLL/JMUix
ISMAgxVX5vTvBDPxiQnjF8E/eaBi0gfT7xICx1jzFO5C3Fxlp/4jvY0CgYEAvDu7
GEzPtr3ggDU0J3VJFBf6+Dq2NlEWdHJbKlLoK/k9eNNG83PnW8OP6I+zrLMLWvNc
pQNVWOHB/sQOM+iDtN64OCrTCA865fuKqBeVGIFZLJ6NLNcDsMBPhfOVBHPNoxUQ
2Dwlqq1udW6Ql9SiE3wz9ppYOH86w9K5DyZwY5UCgYAe0ZmzILH30wZuUsj3yVVD
GJl8+ZSXCIaSxJsUpyHevHiUSO2BGLUkuslrPkX41uZ/+1GtdYQEtt7kEgoInzHf
ya06vgdQ6IAY5eb1ykQuD9JAEzP9jFj8/FTAQR8SFcN4IKpa0GlvRAAn/2cBdAQY
p4q6dkKrT0oeX4JtMvaKsQKBgQCZh2aM5WmuNaT9LWgCnwkiGIUdHlYsa2sTQ4rU
NJcl9r6K5FjEjU6xbAretwbn34ltf32bIeLlAg5HDAZBlG6Igfhj55oEwtdZaheo
DsQPHsFrQU8Iub9K1TCHoytyXDnnwHDizfwzAA5OPgY1sLsZhX6krzMxsaRuwFss
3j9hGQKBgAssgWovAxinLLsAFUYCoSiDCaTDl7ANfz+NFKKPFctxK6J00UlOBOvn
1pcIAnZzxBbHiGh9HA3eI4tkaq+W1RCYt+X9Kz15EJCjmx30el2JeXSDPuiRVqvs
e4G0kgzId6FsWba0h4PDRb3hpEf+eZZdbtTPTAgGrX8cRU+b1lvH
-----END RSA PRIVATE KEY-----
EOF
  }
}

module "cluster-issuer-gts-prod" {
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
        email                       = "systems@facets.cloud"
        server                      = "https://dv.acme-v02.api.pki.goog/directory"
        disableAccountKeyGeneration = true
        privateKeySecretRef = {
          name = kubernetes_secret.google-trust-services-prod-account-key.metadata[0].name
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
        email                       = "systems@facets.cloud"
        server                      = "https://dv.acme-v02.api.pki.goog/directory"
        disableAccountKeyGeneration = true
        privateKeySecretRef = {
          name = kubernetes_secret.google-trust-services-prod-account-key.metadata[0].name
        }
        solvers = [
          {
            http01 = {
              ingress = {
                podTemplate = {
                  spec = {
                    nodeSelector = var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors
                    tolerations  = concat(var.environment.default_tolerations, var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations)
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
