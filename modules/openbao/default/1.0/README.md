# OpenBao Cluster with Static Seal Auto-Unseal

This Facets module deploys OpenBao with automatic unsealing using a static seal mechanism. The module uses Helm to deploy OpenBao and a Kubernetes Job to handle initialization, Raft cluster setup, and policy configuration.

## Features

- **Static Seal Auto-Unseal**: Pods automatically unseal on restart without manual intervention
- **Helm-based Deployment**: Uses the official OpenBao Helm chart
- **Kubernetes Job Initialization**: Automated initialization and cluster setup
- **High Availability**: Raft consensus with configurable replicas
- **Kubernetes Auth Integration**: Pre-configured Kubernetes authentication backend
- **Custom Policy Support**: Define policies, roles, and service account bindings
- **KV v2 Secrets Engine**: Pre-enabled at `cp-secrets/` path
- **Resource Management**: Configurable CPU/memory requests and limits
- **Persistent Storage**: Automatic PVC creation for each replica

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Random Key    │───▶│  K8s Secret     │───▶│  Helm Release   │
│   Generation    │    │  (Unseal Key)   │    │  (OpenBao Pods) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                       ┌─────────────────────────────────────────┐
                       │      Kubernetes Init Job                │
                       │  1. Initialize leader (openbao-0)       │
                       │  2. Store root token & recovery keys    │
                       │  3. Join Raft nodes (HA mode)           │
                       │  4. Configure Kubernetes auth           │
                       │  5. Enable KV v2 secrets engine         │
                       │  6. Create custom policies & roles      │
                       └─────────────────────────────────────────┘
                                         │
                                         ▼
                       ┌─────────────────────────────────────────┐
                       │      Auto-Unsealed OpenBao Cluster      │
                       │  - Static seal with env var key         │
                       │  - Pods auto-unseal on restart          │
                       │  - Raft HA (if replicas > 1)            │
                       │  - Ready for secret management          │
                       └─────────────────────────────────────────┘
```

## How Static Seal Works

Unlike traditional Shamir seal (which requires manual unseal keys), static seal:
- Uses a pre-generated encryption key stored in a Kubernetes secret
- Injects the key into pods via environment variable (`OPENBAO_UNSEAL_KEY`)
- OpenBao automatically unseals on startup using the static key
- Pods can restart without manual intervention
- Recovery keys (not unseal keys) are generated during initialization for emergency access

## Environment as Dimension

The module is environment-aware through `var.environment`:
- **Namespace**: Deployed in the namespace specified in metadata
- **Tolerations**: Uses `var.environment.default_tolerations` for spot instance support
- **Tags**: Applies `var.environment.cloud_tags` to all resources
- **Storage**: PVCs are created per-environment, allowing different storage configurations

## Resources Created

- **Helm Release**: OpenBao cluster with static seal configuration
- **Random ID**: 32-byte encryption key for static seal
- **Kubernetes Secret**: Stores the static unseal key
- **PersistentVolumeClaims**: One per replica for data storage
- **ServiceAccount + RBAC**: For the initialization job
- **Kubernetes Job**: Handles initialization and cluster setup
- **Secret (created by job)**: Stores root token and recovery keys

## Usage

### Basic Standalone Deployment

```yaml
kind: openbao-cluster
flavor: default
version: "1.0"
spec:
  namespace: "openbao"
  release_name: "openbao"
  storage_type: "file"
  server_replicas: 1
```

### High Availability Deployment

```yaml
kind: openbao-cluster
flavor: default
version: "1.0"
spec:
  namespace: "openbao-prod"
  release_name: "openbao-ha"
  storage_type: "raft"
  server_replicas: 3
  storage_size: "20Gi"

  server_resources:
    requests:
      cpu: "1000m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "1Gi"
```

### With Custom Policies

```yaml
kind: openbao-cluster
flavor: default
version: "1.0"
spec:
  namespace: "openbao"
  release_name: "openbao"
  storage_type: "raft"
  server_replicas: 3

  openbao:
    policies:
      app-readonly:
        service_account_name: "my-app-sa"
        role_name: "app-role"
        policy: |
          # Read-only access to app secrets
          path "cp-secrets/data/app/*" {
            capabilities = ["read", "list"]
          }

      admin-full:
        service_account_name: "admin-sa"
        role_name: "admin-role"
        policy: |
          # Full access to all secrets
          path "cp-secrets/*" {
            capabilities = ["create", "read", "update", "delete", "list"]
          }
```

## Configuration Reference

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `namespace` | string | Kubernetes namespace for deployment |
| `release_name` | string | Helm release name |
| `storage_type` | string | Storage backend: `raft` (HA) or `file` (standalone) |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `chart_version` | string | "0.18.4" | OpenBao Helm chart version |
| `server_replicas` | integer | 1 | Number of OpenBao replicas (1-10) |
| `server_resources` | object | See defaults | CPU/memory requests and limits |
| `ui_enabled` | boolean | true | Enable OpenBao web UI |
| `storage_size` | string | "10Gi" | PVC size per replica |
| `pvc_labels` | object | {} | Additional labels for PVCs |
| `unseal_secret_name` | string | `{instance_name}-unseal-key` | Name of unseal key secret |
| `openbao.policies` | object | {} | Custom policies and roles |
| `openbao.values` | object | {} | Additional Helm values |

### Policy Configuration

Define custom policies with Kubernetes auth integration:

```yaml
openbao:
  policies:
    {policy-name}:
      service_account_name: "k8s-service-account"
      role_name: "openbao-auth-role"
      policy: |
        path "cp-secrets/data/my-app/*" {
          capabilities = ["read"]
        }
```

Each policy creates:
1. An OpenBao policy with the specified HCL
2. A Kubernetes auth role bound to the service account
3. Automatic binding allowing the SA to authenticate and assume the policy

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Deployment namespace |
| `release_name` | Helm release name |
| `service_name` | Kubernetes service name |
| `service_url` | Internal service URL |
| `ui_enabled` | Whether UI is enabled |
| `ui_url` | UI access URL (if enabled) |
| `health_check_url` | Health check endpoint |
| `unseal_secret_name` | Name of unseal key secret |
| `init_keys_secret_name` | Name of init keys secret (root token & recovery keys) |
| `storage_type` | Storage backend type |
| `server_replicas` | Number of replicas |
| `root_token` | Root token (sensitive) |
| `recovery_keys` | Recovery keys (sensitive) |

## Security Considerations

### Static Unseal Key

- The 32-byte unseal key is generated using Terraform's `random_id` resource
- Stored in a Kubernetes secret with `prevent_destroy = true` lifecycle
- Injected into pods via environment variable
- Key is never exposed in logs or Terraform state (base64 encoded)
- **Important**: Backup this secret - losing it means losing access to sealed data

### Root Token & Recovery Keys

- Root token is stored in `{release_name}-init-keys` secret
- Recovery keys are for emergency access if static seal fails
- Rotate the root token regularly using OpenBao's token rotation
- Limit RBAC access to these secrets

### Network Security

- Service uses ClusterIP type (internal only)
- TLS is disabled by default (enable for production)
- Use Kubernetes network policies to restrict access
- Consider using a service mesh for mTLS

### RBAC

- Init job uses a dedicated ServiceAccount with minimal permissions
- Only has access to: pods, pods/exec, secrets, statefulsets
- Permissions scoped to the deployment namespace only

## Operations

### Accessing OpenBao

```bash
# Get the root token
kubectl get secret openbao-init-keys -n openbao -o jsonpath='{.data.root-token}' | base64 -d

# Port forward to access UI
kubectl port-forward svc/openbao -n openbao 8200:8200

# Access via browser
open http://localhost:8200/ui
```

### Using Kubernetes Auth (from a Pod)

```bash
# Inside a pod with the configured service account
export VAULT_ADDR="http://openbao.openbao.svc.cluster.local:8200"
export SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Login
vault write auth/kubernetes/login role=app-role jwt=$SA_TOKEN

# Use the token to access secrets
vault kv get cp-secrets/my-app/config
```

### Scaling the Cluster

To add more replicas:
1. Update `server_replicas` in your configuration
2. Apply the changes
3. The init job will automatically join new nodes to the Raft cluster

### Backup and Recovery

```bash
# Backup critical secrets
kubectl get secret openbao-unseal-key -n openbao -o yaml > unseal-key-backup.yaml
kubectl get secret openbao-init-keys -n openbao -o yaml > init-keys-backup.yaml

# Take Raft snapshots (using root token)
export VAULT_TOKEN="<root-token>"
vault operator raft snapshot save backup.snap
```

## Troubleshooting

### Init Job Fails

```bash
# Check job logs
kubectl logs -n openbao job/openbao-init-xxxxx

# Common issues:
# - Pod not ready: Increase timeout or check pod status
# - RBAC issues: Verify ServiceAccount permissions
# - Network issues: Check service connectivity
```

### Pods Not Auto-Unsealing

```bash
# Check if unseal key secret exists
kubectl get secret openbao-unseal-key -n openbao

# Verify environment variable is injected
kubectl exec -n openbao openbao-0 -- env | grep OPENBAO_UNSEAL_KEY

# Check pod logs for seal errors
kubectl logs -n openbao openbao-0
```

### Raft Node Not Joining

```bash
# Check node status
kubectl exec -n openbao openbao-1 -- bao status

# Manually join if needed (using root token)
kubectl exec -n openbao openbao-1 -- bao operator raft join \
  http://openbao-0.openbao-internal.openbao.svc.cluster.local:8200
```

### Check Cluster Status

```bash
# View Raft peers
export VAULT_TOKEN="<root-token>"
vault operator raft list-peers

# Check seal status
vault status
```

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- Persistent volume provisioner (for PVCs)
- RBAC enabled
- Kubernetes provider configured via inputs

## Limitations

- Only supports Azure cloud (as configured)
- TLS is not enabled by default
- Static seal key rotation requires manual process
- Single Kubernetes cluster deployments only
- Raft storage requires persistent volumes

## Advanced Configuration

### Custom Helm Values

Override any Helm chart value:

```yaml
openbao:
  values:
    server:
      extraEnvironmentVars:
        FOO: "bar"
      annotations:
        custom-annotation: "value"
```

### Storage Backend Selection

**File Storage** (Standalone):
- Single replica only
- Data stored in PVC
- No HA capabilities
- Simpler setup

**Raft Storage** (HA):
- Multiple replicas supported
- Distributed consensus
- Automatic failover
- Requires internal service for inter-pod communication

## License

This module is part of the Facets platform and follows the same licensing terms.
