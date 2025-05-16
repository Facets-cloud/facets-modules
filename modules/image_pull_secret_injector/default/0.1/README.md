# Image Pull Secret Injector Module

## Overview

This Terraform module deploys the **Image Pull Secret Injector** as a Helm release in a Kubernetes cluster. It automatically injects image pull secrets into service accounts to allow seamless access to private container registries (e.g., Artifactory, Docker Hub).

This is especially useful in enterprise environments where workloads are spread across namespaces and need access to private registries without manually managing secrets in every namespace.

## Lifecycle & Input Type

- **Lifecycle**: `ENVIRONMENT`
- **Input Type**: `instance`

---

## Inputs

The module requires the following inputs:

### ✅ `kubernetes_details` *(required)*  
Reference to the Kubernetes cluster where the image pull secret injector should be deployed.

### ✅ `artifactories` *(required)*  
Reference to one or more configured container registries. These artifactories are used to retrieve image pull secrets that the injector will distribute across namespaces.

## Spec Configuration

The main configuration is defined under the `spec` block.

### ✅ `size` *(optional)*  
Defines resource constraints for the image pull secret injector deployment.

- `cpu_limit` (`string`)  
  The CPU limit for the injector container.  
  _Example_: `"200m"`, `"1"`

- `memory_limit` (`string`)  
  The memory limit for the injector container.  
  _Example_: `"256Mi"`, `"1Gi"`

### ✅ `values` *(optional)*  
YAML-formatted override values passed directly to the Helm chart for advanced customization.

**Example:**
```yaml
values:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux