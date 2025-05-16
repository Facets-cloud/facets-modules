# MongoDB Kubernetes Flavor Documentation (v0.3)

## Overview

The `mongo - k8s` flavor (v0.3) enables the deployment of MongoDB instances within Kubernetes environments. This version builds on v0.2 by introducing a new `metadata` section that allows specification of the target **namespace** for MongoDB deployment. It remains suitable for teams deploying MongoDB within self-managed or cloud-managed Kubernetes clusters.

Supported platforms:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

### Metadata

- **namespace** (`string`, optional, default: `"default"`)  
  Kubernetes namespace where MongoDB should be deployed.

---

### Spec

#### Required Fields

- **authenticated** (`boolean`)  
  Whether to enable authentication (username/password) for MongoDB.

- **mongodb_version** (`string`)  
  Version of MongoDB to deploy. Supported versions:
  - `4.4.15`
  - `5.0.24`
  - `6.0.13`
  - `7.0.11`
  - `7.0.14`
  - `8.0.1`

- **size** (`object`)  
  MongoDB cluster sizing and resource requests.

##### Nested in `size`:

- **instance_count** (`integer`, 1–10)  
  Number of MongoDB instances.

- **cpu** (`string`)  
  CPU request. Accepts values like:
  - `"500m"`, `"1000m"` (millicores)
  - `"1"`, `"2"` (cores)

- **cpu_limit** (`string`)  
  Maximum CPU allocation per instance (must be ≥ `cpu`).

- **memory** (`string`)  
  Memory request. Examples:
  - `"800Mi"`, `"1.5Gi"`

- **memory_limit** (`string`)  
  Maximum memory allocation (must be ≥ `memory`).

- **volume** (`string`)  
  Volume size, e.g., `"10Gi"`, `"50Gi"`.

## Usage

Use the v0.3 flavor when:

- You want to control **namespace targeting** for MongoDB deployments in Kubernetes.
- You need precise control over CPU/memory **requests and limits**.
- You're operating in **multi-cloud or hybrid** Kubernetes clusters.
- You require a self-managed MongoDB cluster with full configurability.
