terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Local values for common configurations
locals {
  metadata     = lookup(var.instance, "metadata", {})
  spec         = lookup(var.instance, "spec", {})
  openbao      = lookup(local.spec, "openbao", {})
  namespace    = lookup(local.metadata, "namespace", "default")
  release_name = lookup(local.spec, "release_name", "openbao")

  # Hardcoded chart details
  chart_repo    = "https://openbao.github.io/openbao-helm"
  chart_name    = "openbao"
  chart_version = lookup(local.spec, "chart_version", "0.18.4")

  # Generate unique resource names
  unseal_secret_name = "${local.release_name}-unseal-key"

  # Common labels
  labels = merge(var.environment.cloud_tags, {
    "app.kubernetes.io/name"       = "openbao"
    "app.kubernetes.io/instance"   = var.instance_name
    "app.kubernetes.io/managed-by" = "facets"
  })

  # Determine HA mode based on storage type
  is_ha_mode = lookup(local.spec, "storage_type", "raft") == "raft"

  # OpenBao configuration with static seal for HA mode
  openbao_config_ha = <<-EOF
    disable_mlock = true

    ui = ${lookup(local.spec, "ui_enabled", true)}

    seal "static" {
      current_key_id = "openbao-unseal-key-v1"
      current_key = "env://OPENBAO_UNSEAL_KEY"
    }

    listener "tcp" {
      tls_disable = true
      address = "[::]:8200"
      cluster_address = "[::]:8201"
    }

    storage "raft" {
      path = "/openbao/data"
    }

    cluster_addr = "http://$(POD_IP):8201"
    api_addr = "http://$(POD_IP):8200"

    log_level = "info"
    EOF

  # OpenBao configuration with static seal for standalone mode
  openbao_config_standalone = <<-EOF
    disable_mlock = true

    ui = ${lookup(local.spec, "ui_enabled", true)}

    seal "static" {
      current_key_id = "openbao-unseal-key-v1"
      current_key = "env://OPENBAO_UNSEAL_KEY"
    }

    listener "tcp" {
      tls_disable = true
      address = "[::]:8200"
    }

    storage "file" {
      path = "/openbao/data"
    }

    log_level = "info"
    EOF

  # Helm values configuration
  constructed_helm_values = {
    global = {
      enabled = true
    }

    server = {
      enabled = true

      replicas = lookup(local.spec, "server_replicas", 1)

      resources = {
        requests = lookup(lookup(local.spec, "server_resources", {}), "requests", {})
        limits   = lookup(lookup(local.spec, "server_resources", {}), "limits", {})
      }

      tolerations = lookup(var.environment, "default_tolerations", [{
        key      = "kubernetes.azure.com/scalesetpriority"
        value    = "spot"
        operator = "Equal"
        effect   = "NoSchedule"
      }])

      dataStorage = {
        enabled = true
      }

      auditStorage = {
        enabled = false
      }

      extraSecretEnvironmentVars = [
        {
          envName    = "OPENBAO_UNSEAL_KEY"
          secretName = local.unseal_secret_name
          secretKey  = "unseal-key"
        }
      ]

      standalone = {
        enabled = !local.is_ha_mode
        config  = local.openbao_config_standalone
      }

      ha = {
        enabled  = local.is_ha_mode
        replicas = lookup(local.spec, "server_replicas", 1)
        raft = {
          enabled   = local.is_ha_mode
          setNodeId = local.is_ha_mode
          config    = local.openbao_config_ha
        }
      }

      service = {
        enabled = true
        type    = "ClusterIP"
        port    = 8200
      }

      serviceAccount = {
        create = true
        name   = "${local.release_name}-sa"
      }

      readinessProbe = {
        enabled = true
        path    = "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
      }

      livenessProbe = {
        enabled             = true
        path                = "/v1/sys/health?standbyok=true"
        initialDelaySeconds = 60
      }
    }

    ui = {
      enabled     = lookup(local.spec, "ui_enabled", true)
      serviceType = "ClusterIP"
    }

    injector = {
      enabled = false
      tolerations = lookup(var.environment, "default_tolerations", [{
        key      = "kubernetes.azure.com/scalesetpriority"
        value    = "spot"
        operator = "Equal"
        effect   = "NoSchedule"
      }])
    }
  }
  user_defined_helm_values = lookup(local.openbao, "values", {})

  # Hardcoded service account names for OpenBao policies
  control_plane_sa_name  = "control-plane-service-sa"
  facets_release_sa_name = "facets-release-pod"
}

# Generate a random 32-byte key for static seal
resource "random_id" "unseal_key" {
  byte_length = 32

  lifecycle {
    ignore_changes = [byte_length]
  }
}

# Create Kubernetes secret to store the unseal key
resource "kubernetes_secret" "unseal_key" {
  metadata {
    name      = local.unseal_secret_name
    namespace = local.namespace
    labels    = local.labels
  }

  data = {
    unseal-key = random_id.unseal_key.b64_std
  }

  type = "Opaque"

  lifecycle {
    prevent_destroy = true
  }
}

# Create PVC for server 
module "openbao_pvc" {
  count             = lookup(local.spec, "server_replicas", 1)
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "data-${local.release_name}-${count.index}"
  namespace         = local.namespace
  provisioned_for   = "${local.release_name}-${count.index}"
  instance_name     = local.release_name
  volume_size       = lookup(local.spec, "storage_size", "10Gi")
  access_modes      = ["ReadWriteOnce"]
  kind              = "openbao"
  additional_labels = lookup(local.spec, "pvc_labels", {})
}

# Deploy OpenBao using Helm
resource "helm_release" "openbao" {
  name       = local.release_name
  repository = local.chart_repo
  chart      = local.chart_name
  version    = local.chart_version
  namespace  = local.namespace

  create_namespace = true

  values = [yamlencode(local.constructed_helm_values), yamlencode(local.user_defined_helm_values)]

  timeout = 600

  depends_on = [kubernetes_secret.unseal_key, module.openbao_pvc]

  lifecycle {
    create_before_destroy = true
  }
}

# Create ServiceAccount for the init job
resource "kubernetes_service_account" "openbao_init" {
  metadata {
    name      = "${local.release_name}-init-sa"
    namespace = local.namespace
    labels    = local.labels
  }

  depends_on = [helm_release.openbao]
}

# Create Role with permissions to exec into pods and manage secrets
resource "kubernetes_role" "openbao_init" {
  metadata {
    name      = "${local.release_name}-init-role"
    namespace = local.namespace
    labels    = local.labels
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec"]
    verbs      = ["get", "list", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets"]
    verbs      = ["get", "list"]
  }

  depends_on = [helm_release.openbao]
}

# Bind the role to the service account
resource "kubernetes_role_binding" "openbao_init" {
  metadata {
    name      = "${local.release_name}-init-binding"
    namespace = local.namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.openbao_init.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.openbao_init.metadata[0].name
    namespace = local.namespace
  }
}

# Kubernetes Job to initialize and maintain OpenBao cluster
# Job is recreated whenever replicas change to join new nodes
resource "kubernetes_job_v1" "openbao_init" {
  metadata {
    name      = "${local.release_name}-init-${md5("${lookup(local.spec, "server_replicas", 1)}")}"
    namespace = local.namespace
    labels    = local.labels
  }

  spec {
    template {
      metadata {
        labels = merge(local.labels, {
          "app" = "${local.release_name}-init"
        })
      }

      spec {
        service_account_name = kubernetes_service_account.openbao_init.metadata[0].name
        restart_policy       = "Never"

        dynamic "toleration" {
          for_each = lookup(var.environment, "default_tolerations", [{
            key      = "kubernetes.azure.com/scalesetpriority"
            value    = "spot"
            operator = "Equal"
            effect   = "NoSchedule"
          }])

          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }

        container {
          name  = "openbao-init"
          image = "alpine/k8s:1.28.3"

          command = ["/bin/bash", "-c"]
          args = [<<-EOF
            set -e

            echo "=== OpenBao Auto-Init and Raft Join Script ==="
            echo "Checking for OpenBao pods..."

            # Wait for at least one OpenBao pod
            kubectl wait --for=condition=ready pod/${local.release_name}-0 -n ${local.namespace} --timeout=300s || {
              echo "ERROR: openbao-0 pod not ready"
              exit 1
            }

            POD_NAME="${local.release_name}-0"
            echo "Found leader pod: $POD_NAME"

            # Check if already initialized
            echo "Checking if OpenBao leader is initialized..."
            if kubectl exec -n ${local.namespace} $POD_NAME -- bao status 2>&1 | grep -q "Initialized.*true"; then
              echo "OpenBao is already initialized."

              # Retrieve root token from existing secret
              if kubectl get secret ${local.release_name}-init-keys -n ${local.namespace} &>/dev/null; then
                echo "Retrieving root token from existing secret..."
                ROOT_TOKEN=$(kubectl get secret ${local.release_name}-init-keys -n ${local.namespace} -o jsonpath='{.data.root-token}' | base64 -d)
              else
                echo "ERROR: OpenBao is initialized but root token secret not found!"
                exit 1
              fi
            else
              echo "Initializing OpenBao with auto-unseal (static seal)..."
              INIT_OUTPUT=$(kubectl exec -n ${local.namespace} $POD_NAME -- bao operator init -format=json)

              echo "OpenBao initialized successfully!"

              # Extract recovery keys and root token using jq
              ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
              RECOVERY_KEYS=$(echo "$INIT_OUTPUT" | jq -r '.recovery_keys_b64 | @json')

              # Store in Kubernetes Secret
              kubectl create secret generic ${local.release_name}-init-keys -n ${local.namespace} \
                --from-literal=root-token="$ROOT_TOKEN" \
                --from-literal=recovery-keys="$RECOVERY_KEYS" \
                --dry-run=client -o yaml | kubectl apply -f -

              echo "Recovery keys and root token stored in secret '${local.release_name}-init-keys'"
              
              echo "OpenBao is now initialized and auto-unsealed via static seal!"
            fi

            # Join additional Raft nodes if running in HA mode
            echo ""
            echo "=== Raft Cluster Setup ==="
            REPLICA_COUNT=$(kubectl get statefulset ${local.release_name} -n ${local.namespace} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
            echo "Detected replica count: $REPLICA_COUNT"

            if [ "$REPLICA_COUNT" -gt 1 ]; then
              echo "HA mode enabled. Processing additional nodes..."

              # Join all non-leader nodes to the cluster
              for i in $(seq 1 $(($REPLICA_COUNT - 1))); do
                POD="${local.release_name}-$i"
                echo ""
                echo "Processing $POD..."

                # Wait for pod to be running (allow time for node provisioning if needed)
                echo "Waiting for $POD to be ready (timeout: 5 minutes)..."
                kubectl wait --for=condition=ready pod/$POD -n ${local.namespace} --timeout=300s || {
                  echo "Warning: $POD not ready after 5 minutes, will retry on next run"
                  continue
                }

                # Check current status
                POD_STATUS=$(kubectl exec -n ${local.namespace} $POD -- bao status 2>&1 || true)

                if echo "$POD_STATUS" | grep -q "Initialized.*true"; then
                  echo "$POD is already initialized and part of cluster"
                  continue
                fi

                # Node is uninitialized, join it to the cluster
                echo "$POD is uninitialized. Joining to Raft cluster..."
                if kubectl exec -n ${local.namespace} $POD -- bao operator raft join \
                  http://${local.release_name}-0.${local.release_name}-internal.${local.namespace}.svc.cluster.local:8200; then
                  echo "Successfully joined $POD to cluster"

                  # Give it a moment to auto-unseal with static seal
                  sleep 3

                  # Verify it unsealed
                  NEW_STATUS=$(kubectl exec -n ${local.namespace} $POD -- bao status 2>&1 || true)
                  if echo "$NEW_STATUS" | grep -q "Sealed.*false"; then
                    echo "$POD is now unsealed and operational"
                  else
                    echo "Warning: $POD joined but may need time to unseal"
                  fi
                else
                  echo "Failed to join $POD - will retry on next run"
                fi
              done

              echo ""
              echo "Raft cluster setup complete!"
            else
              echo "Single replica deployment - no additional nodes to join"
            fi

            # Configure OpenBao policies and auth
            echo ""
            echo "Configuring OpenBao policies and Kubernetes auth..."

            # Enable Kubernetes auth method
            echo "Enabling Kubernetes auth method..."
            kubectl exec -n ${local.namespace} $POD_NAME -- env BAO_TOKEN="$ROOT_TOKEN" bao auth enable kubernetes || echo "Kubernetes auth already enabled"

            # Detect Kubernetes issuer from JWT token
            echo "Detecting Kubernetes issuer from JWT token..."
            TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
            PAYLOAD=$(echo "$TOKEN" | cut -d. -f2)

            # Add padding for base64 decoding if needed
            MOD=$(($(echo -n "$PAYLOAD" | wc -c) % 4))
            if [ $MOD -eq 2 ]; then
              PAYLOAD="$${PAYLOAD}=="
            elif [ $MOD -eq 3 ]; then
              PAYLOAD="$${PAYLOAD}="
            fi

            # Extract issuer from JWT payload
            ISSUER=$(echo "$PAYLOAD" | base64 -d 2>/dev/null | grep -o '"iss":"[^"]*"' | cut -d'"' -f4)

            if [ -z "$ISSUER" ]; then
              echo "Warning: Could not detect issuer from JWT token, using default configuration"
              ISSUER_PARAM=""
            else
              echo "Detected issuer: $ISSUER"
              ISSUER_PARAM="issuer='$ISSUER'"
            fi

            # Configure Kubernetes auth backend with auto-detected issuer
            echo "Configuring Kubernetes auth backend..."
            kubectl exec -n ${local.namespace} $POD_NAME -- sh -c "
              export BAO_TOKEN='$ROOT_TOKEN'
              bao write auth/kubernetes/config \
                kubernetes_host='https://kubernetes.default.svc:443' \
                kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
                $ISSUER_PARAM
            "

            # Enable KV v2 secrets engine at 'secret/' path
            echo "Enabling KV v2 secrets engine at secret/ path..."
            kubectl exec -n ${local.namespace} $POD_NAME -- env BAO_TOKEN="$ROOT_TOKEN" bao secrets enable -path=secret -version=2 kv || echo "KV v2 secrets engine already enabled at secret/"

            # Create read-write policy for control-plane-service-sa
            echo "Creating read-write policy for control-plane-service-sa..."
            kubectl exec -n ${local.namespace} $POD_NAME -- sh -c "
              export BAO_TOKEN='$ROOT_TOKEN'
              bao policy write control-plane-rw - <<'POLICY'
# Full read-write access to all secrets
path \"secret/*\" {
  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]
}

path \"secret/data/*\" {
  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]
}

path \"secret/metadata/*\" {
  capabilities = [\"list\", \"read\", \"delete\"]
}

# System health check
path \"sys/health\" {
  capabilities = [\"read\"]
}
POLICY
            "

            # Create read-only policy for facets-release-pod
            echo "Creating read-only policy for facets-release-pod..."
            kubectl exec -n ${local.namespace} $POD_NAME -- sh -c "
              export BAO_TOKEN='$ROOT_TOKEN'
              bao policy write facets-release-readonly - <<'POLICY'
# Read-only access to all secrets
path \"secret/*\" {
  capabilities = [\"read\", \"list\"]
}

path \"secret/data/*\" {
  capabilities = [\"read\", \"list\"]
}

path \"secret/metadata/*\" {
  capabilities = [\"read\", \"list\"]
}

# System health check
path \"sys/health\" {
  capabilities = [\"read\"]
}
POLICY
            "

            # Create auth role for control-plane-service-sa
            echo "Creating auth role for control-plane-service-sa..."
            kubectl exec -n ${local.namespace} $POD_NAME -- env BAO_TOKEN="$ROOT_TOKEN" bao write auth/kubernetes/role/control-plane-role \
              bound_service_account_names=${local.control_plane_sa_name} \
              bound_service_account_namespaces='*' \
              policies=control-plane-rw \
              ttl=72h

            # Create auth role for facets-release-pod
            echo "Creating auth role for facets-release-pod..."
            kubectl exec -n ${local.namespace} $POD_NAME -- env BAO_TOKEN="$ROOT_TOKEN" bao write auth/kubernetes/role/facets-release-role \
              bound_service_account_names=${local.facets_release_sa_name} \
              bound_service_account_namespaces='*' \
              policies=facets-release-readonly \
              ttl=72h

            echo ""
            echo "OpenBao configuration complete!"
            echo "- Policies created: control-plane-rw, facets-release-readonly"
            echo "- Auth roles created: control-plane-role, facets-release-role"
          EOF
          ]

          env {
            name  = "BAO_ADDR"
            value = "http://${local.release_name}-openbao.${local.namespace}.svc.cluster.local:8200"
          }
        }
      }
    }

    backoff_limit = 3
  }

  wait_for_completion = true

  timeouts {
    create = "15m"
  }

  depends_on = [
    helm_release.openbao,
    kubernetes_role_binding.openbao_init
  ]

  lifecycle {
    replace_triggered_by = [helm_release.openbao]
  }
}

# Data source to read the init keys secret (for outputs)
data "kubernetes_secret_v1" "openbao_init_keys" {
  metadata {
    name      = "${local.release_name}-init-keys"
    namespace = local.namespace
  }

  depends_on = [kubernetes_job_v1.openbao_init]
}
