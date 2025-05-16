# Kubernetes Cluster – AWS EKS Flavor (v0.2)

## Overview

The `kubernetes_cluster - aws_eks` flavor (v0.2) provides a declarative interface to define and manage an **Amazon EKS (Elastic Kubernetes Service)** cluster using standard configuration schemas.

This module enables defining core cluster settings, node pools (default, spot, and fallback), logging, KMS integration, and addon management—all tailored for AWS environments.

Supported platform:
- AWS

> 🛠️ Designed for use in fully-managed infrastructure setups where cluster lifecycle and node pool scaling are declaratively managed.

---

## Configurability

### `spec` (object)

#### `cluster` (object)

- **`cloudwatch_log_retention_days`** (`number`, default: `365`)  
  Days to retain CloudWatch logs.

- **`public_cidr_whitelist`** (`string`, default: `0.0.0.0/0`)  
  Comma-separated CIDR blocks allowed to access the EKS public API server.

- **`kms_keys`** (`object`)  
  - `deletion_window_in_days` (`number`, default: `7`)  
  - `enable_rotation` (`boolean`, default: `false`)  
  - `rotation_period_in_days` (`number`, default: `90`)

- **`default_reclaim_policy`** (`string`, default: `Delete`)  
  Enum: `Delete`, `Retain`

#### `nodepools` (object)

- **`default`**  
  - `instance_types` (`array`, **required**)  
  - `root_disk_volume` (`number`, default: `100`)  
  - `node_lifecycle_type` (`string`, default: `SPOT`)  
  - `max_nodes` (`number`, default: `200`)  
  - Optional AMI filters and IDs

- **`facets_dedicated`**  
  - `enable` (`boolean`)  
  - Requires: `instance_type`, with optional overrides (e.g., AMI ID, disk size)

- **`ondemand_fallback`**  
  - `enable` (`boolean`)  
  - Requires: `instance_type`, `max_nodes`

#### `tags` (object)  
YAML key-value pairs added as tags to the EKS cluster.

#### `addons` (object of named blocks)

Each addon block supports:
- `enable` (`boolean`)  
- `configuration_values` (`string`)  
- `resolve_conflicts` (`boolean`)  
- `addon_version` (`string`)  
- `tags` (YAML `object`)  
- `preserve` (`boolean`)  
- `service_account_role_arn` (`string`)

---

## Usage

To use this flavor, define a resource of kind `kubernetes_cluster` with flavor `aws_eks` and version `0.2`. You can configure cluster-level settings like CloudWatch log retention, CIDR access control, KMS key policies, and node pool types (on-demand, spot, or dedicated). Nodepools require specifying instance types and optionally allow tuning disk size, max nodes, and AMI details. You can also enable addons with custom configuration and tagging. This module is suitable for automated deployments in AWS environments using managed Kubernetes infrastructure.
