locals {
  advanced                 = lookup(var.instance, "advanced", {})
  k8s                      = lookup(local.advanced, "k8s", {})
  vault                    = lookup(local.k8s, "vault", {})
  user_defined_helm_values = lookup(local.vault, "values", {})
  namespace                = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  spec                     = lookup(var.instance, "spec", {})
  size                     = lookup(local.spec, "size", {})
  replica_count            = tonumber(lookup(local.size, "instance_count", 1))
  standalone               = local.replica_count == 1 ? true : false
  limit_value = contains(keys(local.size), "cpu") && contains(keys(local.size), "memory") ? {
    limits = {
      cpu    = lookup(local.size, "cpu_limit", local.size.cpu)
      memory = lookup(local.size, "memory_limit", local.size.memory)
    }
  } : {}
  requests_value = contains(keys(local.size), "cpu") && contains(keys(local.size), "memory") ? {
    requests = {
      cpu    = local.size.cpu
      memory = local.size.memory
    }
  } : {}
  constructed_helm_values = {
    server = {
      image = {
        tag = local.spec.vault_version
      }
      standalone = {
        enabled = local.standalone
      }
      ha = {
        enabled  = !local.standalone
        replicas = !local.standalone ? local.replica_count : 0
      }
      resources   = merge(local.limit_value, local.requests_value)
      tolerations = var.environment.default_tolerations
      dataStorage = {
        size = local.size.volume
      }
      postStart = ["/bin/sh", "-c",
        <<-EOT
          sleep 10
          vault operator init -key-shares=1 -key-threshold=1 >> /vault/data/init.txt
          cat /vault/data/init.txt | grep "Key " | awk '{print $NF}' | xargs -I{} vault operator unseal {}
          echo $(cat /vault/data/init.txt | grep "Initial Root Token" | awk '{print $NF}') > /vault/data/root_token
        EOT
      ]
    }
    injector = {
      tolerations = var.environment.default_tolerations
    }
  }
}

module "name" {
<<<<<<< HEAD
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
=======
  source          = "../../3_utility/name"
>>>>>>> 9fd760b (Vault Terraform module (#227))
  is_k8s          = true
  globally_unique = false
  resource_type   = "vault"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 30
}

module "vault-pvc" {
  count             = local.replica_count == 1 ? 1 : 0
<<<<<<< HEAD
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
=======
  source            = "../../3_utility/pvc"
>>>>>>> 9fd760b (Vault Terraform module (#227))
  name              = "data-${module.name.name}-0"
  namespace         = local.namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.size.volume
  provisioned_for   = "${module.name.name}-0"
  instance_name     = module.name.name
  kind              = "vault"
  additional_labels = lookup(lookup(local.user_defined_helm_values, "dataStorage", {}), "lables", {})
  cloud_tags        = var.environment.cloud_tags
}

resource "helm_release" "vault" {
  depends_on      = [module.vault-pvc]
  name            = module.name.name
  repository      = "https://helm.releases.hashicorp.com"
  chart           = "vault"
  version         = lookup(local.vault, "chart_version", "0.28.1")
  namespace       = local.namespace
  wait            = true
  cleanup_on_fail = true
  timeout         = lookup(local.vault, "timeout", "300")
  max_history     = 10
  atomic          = lookup(local.vault, "atomic", false)
  values = [
    yamlencode(local.constructed_helm_values),
    yamlencode(local.user_defined_helm_values)
  ]
}

resource "null_resource" "save_root_token" {
  depends_on = [helm_release.vault]
  provisioner "local-exec" {
    environment = {
      SERVER = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.auth.host
      CA     = base64encode(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.auth.cluster_ca_certificate)
      TOKEN  = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.auth.token
    }
    command = <<EOT
    MAX_RETRIES=10
    WAIT_TIME=15
    i=1
    while [ $i -le $MAX_RETRIES ]
    do
        POD_STATUS=$(/bin/bash ../tfmain/scripts/run_with_kubeconfig.sh kubectl get pod ${module.name.name}-0 -n ${local.namespace} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$POD_STATUS" = "True" ]; then
            kubectl --kubeconfig=/tmp/kubeconfig cp ${module.name.name}-0:/vault/data/root_token root_token -n ${local.namespace}
            kubectl --kubeconfig=/tmp/kubeconfig create secret generic ${module.name.name}-secret --from-file=root_token -n ${local.namespace}
            exit 0
        else
            echo "Vault pod is not ready yet. Waiting for $WAIT_TIME seconds..."
            sleep $WAIT_TIME
        fi
        i=$((i + 1))
    done
    echo "Pod did not become ready after $MAX_RETRIES attempts."
    exit 1
    EOT
  }
}

data "kubernetes_secret" "vault_root_token" {
  depends_on = [null_resource.save_root_token]
  metadata {
    name      = "${module.name.name}-secret"
    namespace = local.namespace
  }
}
