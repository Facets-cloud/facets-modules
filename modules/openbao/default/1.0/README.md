# Auto-Unsealing OpenBao Cluster

This Facets module deploys OpenBao with automatic initialization and unsealing capabilities using configurable key shares and threshold. The module uses Helm to deploy OpenBao and implements auto-unseal functionality through Terraform null resources that execute API calls against the OpenBao cluster.

## Features

- **Helm-based Deployment**: Uses the official Vault Helm chart (compatible with OpenBao)
- **Automatic Initialization**: Initializes OpenBao with configurable key shares and threshold
- **Auto-Unseal**: Automatically unseals OpenBao using stored unseal keys
- **Secure Key Storage**: Stores unseal keys and root token in Kubernetes secrets
- **Flexible Storage Backends**: Supports file, Raft, and Azure storage backends
- **High Availability**: Configurable replicas with Raft consensus
- **TLS Support**: Optional TLS configuration with multiple certificate sources
- **UI Access**: Optional web UI with ingress support
- **Resource Management**: Configurable CPU/memory requests and limits

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Helm Release  │    │  Null Resource  │    │  Null Resource  │
│   (OpenBao)     │───▶│  (Initialize)   │───▶│  (Auto-Unseal)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  OpenBao Pods   │    │  K8s Secrets    │    │  Unsealed       │
│                 │    │  - Unseal Keys  │    │  OpenBao        │
│                 │    │  - Root Token   │    │  Ready for Use  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Usage

### Basic Configuration

```yaml
kind: openbao-cluster
flavor: auto-unseal
version: "1.0"
spec:
  namespace: "openbao"
  release_name: "my-openbao"
  key_shares: 5
  key_threshold: 3
  storage_backend:
    type: "raft"
```

### Advanced Configuration

```yaml
kind: openbao-cluster
flavor: auto-unseal
version: "1.0"
spec:
  namespace: "openbao-prod"
  release_name: "openbao-ha"
  key_shares: 7
  key_threshold: 4
  
  # High availability setup
  server_replicas: 3
  storage_backend:
    type: "raft"
    config:
      retry_join:
        - "openbao-ha-0.openbao-ha-internal:8201"
        - "openbao-ha-1.openbao-ha-internal:8201"
        - "openbao-ha-2.openbao-ha-internal:8201"
  
  # Resource configuration
  server_resources:
    requests:
      cpu: "1000m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "1Gi"
  
  # TLS and UI
  tls_config:
    enabled: true
    cert_source: "cert-manager"
  ui_enabled: true
  ingress_enabled: true
  
  # Custom timeout
  init_timeout: "600s"
```

## Configuration Reference

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `key_shares` | integer | Number of key shares to generate (1-255) |
| `key_threshold` | integer | Number of shares required to unseal (1-255, ≤ key_shares) |
| `namespace` | string | Kubernetes namespace (created automatically) |
| `release_name` | string | Helm release name |
| `storage_backend` | object | Storage backend configuration |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `helm_chart_version` | string | "0.28.1" | Vault Helm chart version |
| `helm_repository` | string | "https://helm.releases.hashicorp.com" | Helm repository URL |
| `secret_name_prefix` | string | "openbao" | Prefix for secrets |
| `server_replicas` | integer | 1 | Number of OpenBao replicas |
| `server_resources` | object | See defaults | CPU/memory requests and limits |
| `ui_enabled` | boolean | true | Enable OpenBao web UI |
| `ingress_enabled` | boolean | false | Create ingress for UI |
| `tls_config` | object | See TLS section | TLS configuration |
| `init_timeout` | string | "300s" | Initialization timeout |

### Storage Backend Options

#### Raft (Recommended for HA)
```yaml
storage_backend:
  type: "raft"
  config:
    retry_join:
      - "pod-0.service:8201"
      - "pod-1.service:8201"
```

#### File (Single Instance)
```yaml
storage_backend:
  type: "file"
  config:
    path: "/openbao/data"
```

#### Azure Key Vault
```yaml
storage_backend:
  type: "azure"
  config:
    tenant_id: "your-tenant-id"
    client_id: "your-client-id"
    client_secret: "your-secret"
    vault_name: "your-keyvault"
```

### TLS Configuration

```yaml
tls_config:
  enabled: true
  cert_source: "self-signed"  # or "cert-manager" or "manual"
```

## Outputs

The module provides the following outputs:

### Default Output
- **Connection details**: Service URLs, namespace, release name
- **UI access**: UI URL if enabled
- **Ingress details**: Ingress host if enabled
- **Secrets**: Names of Kubernetes secrets containing keys and tokens
- **Configuration**: Deployment configuration details
- **Health check**: Health check endpoint URL

### Additional Outputs
- `root_token_secret_name`: Name of secret containing root token
- `unseal_keys_secret_name`: Name of secret containing unseal keys
- `namespace`: Deployment namespace
- `service_details`: Service connection details for other apps
- `helm_release`: Helm release information

## Security Considerations

### Unseal Keys Storage
- Unseal keys are stored in Kubernetes secrets with base64 encoding
- Secrets are labeled for easy identification and management
- Consider implementing additional encryption for secrets at rest

### Root Token Protection
- Root token is stored in a separate Kubernetes secret
- Rotate the root token regularly using OpenBao's token rotation features
- Limit access to the root token secret using RBAC

### Network Security
- Use TLS for all communications when possible
- Configure network policies to restrict pod-to-pod communication
- Use ingress with proper authentication for UI access

## Operations

### Accessing OpenBao
```bash
# Get the root token
kubectl get secret openbao-root-token -n openbao -o jsonpath='{.data.root-token}' | base64 -d

# Port forward to access UI
kubectl port-forward svc/openbao-vault -n openbao 8200:8200

# Access via browser
open http://localhost:8200/ui
```

### Manual Unseal (if needed)
```bash
# Get unseal keys
kubectl get secret openbao-init-keys -n openbao -o jsonpath='{.data.unseal-keys}' | base64 -d | base64 -d

# Unseal manually (if auto-unseal fails)
kubectl exec -n openbao openbao-vault-0 -- openbao operator unseal <key>
```

### Backup and Recovery
- Regularly backup the Kubernetes secrets containing unseal keys
- Consider using Velero or similar tools for cluster-level backups
- Test recovery procedures in non-production environments

## Troubleshooting

### Common Issues

1. **Initialization Timeout**
   - Increase `init_timeout` value
   - Check pod logs: `kubectl logs -n <namespace> <pod-name>`
   - Verify network connectivity

2. **Unseal Failures**
   - Check if secrets exist and contain valid keys
   - Verify key threshold is not greater than available keys
   - Check OpenBao pod status and logs

3. **Helm Deployment Issues**
   - Verify Helm repository is accessible
   - Check chart version compatibility
   - Review Helm release status: `helm status <release-name> -n <namespace>`

### Debugging Commands
```bash
# Check OpenBao status
kubectl exec -n <namespace> <pod-name> -- openbao status

# View initialization logs
kubectl logs -n <namespace> <pod-name> | grep init

# Check secrets
kubectl get secrets -n <namespace> | grep openbao

# Describe Helm release
helm get values <release-name> -n <namespace>
```

## Prerequisites

- Kubernetes cluster with RBAC enabled
- Helm 3.x installed and configured
- `kubectl` access to the target cluster
- `jq` utility for JSON processing (required for auto-unseal scripts)

## Limitations

- Currently supports single-cluster deployments only
- Auto-unseal requires `kubectl` and `jq` to be available in Terraform execution environment
- Raft storage backend requires persistent volumes
- TLS certificate management is basic (consider cert-manager for production)

## Contributing

This module follows Facets module development standards. When contributing:

1. Maintain backward compatibility
2. Update documentation for any new features
3. Add appropriate validation rules
4. Test with different storage backends
5. Follow Terraform best practices

## License

This module is part of the Facets platform and follows the same licensing terms.