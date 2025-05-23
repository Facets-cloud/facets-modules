# Helm Module

## Overview

This module provisions a **Helm chart deployment** into a Kubernetes cluster. It allows platform users to install and manage applications using Helm charts declaratively by specifying the chart name, version, repository, target namespace, and custom values.

This module supports **AWS**, **Azure**, **GCP**, and **self-managed Kubernetes** clusters.

---

## Configurability

**`metadata`**

- `metadata`:  
  Optional metadata for the Helm release (e.g., name or description).

**`spec`**

**`helm`**: 
Defines the chart source and deployment settings.

- **`chart`**: 
  The name of the Helm chart.  
  _Example_: `nginx`, `datadog`

- **`repository`**:  
  URL to the Helm chart repository.  
  _Example_: `https://helm.nginx.com/stable`

- **`version`**:  
  The specific chart version to install.  
  _Example_: `1.2.3`

- **`namespace`**:  
  Kubernetes namespace in which to install the chart. Defaults to `default` if not provided.

- **`wait`**:  
  Whether to wait until all resources are ready before completing the install or upgrade.

- **`repository_username`**:  
  Username for authenticating to a private Helm repository.

- **`repository_password`**: 
  Password for authenticating to a private Helm repository.

**`values`**:  
Custom configuration values to override the default `values.yaml` of the Helm chart.  
This should be a YAML-compatible object.  
_Example_:

```yaml
values:
  replicas: 3
  resources:
    limits:
      cpu: 500m
      memory: 256Mi
```

## Usage

Once configured and deployed:

The specified Helm chart will be installed in your target Kubernetes cluster.

If configured with wait = true, the module will wait for all components to be ready before marking the deployment complete.

Any updates to chart version, values, or namespace will trigger an upgrade of the release.

## Notes

Make sure the Kubernetes cluster you're targeting is accessible and has Helm properly initialized.

Use wait: true if your application requires all pods to be running before continuing with dependent deployments.

Always validate YAML passed into the values field to avoid syntax errors.

This module supports both public and private Helm chart repositories.