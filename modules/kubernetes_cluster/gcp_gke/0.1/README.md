# Kubernetes Cluster – GCP GKE Flavor (v0.1)

## Overview

The `kubernetes_cluster - gcp_gke` flavor (v0.1) provisions a **Google Kubernetes Engine (GKE)** cluster in GCP, with support for advanced features like private nodes, node auto-provisioning, IAM roles for service accounts, and multi-availability zone deployments. This flavor is ideal for teams looking to run container workloads on Google Cloud with granular control over nodepools and cluster configuration.

Supported platform:
- GCP

> ⚙️ Optimized for environments requiring secure, scalable, and compliant Kubernetes clusters on GKE with IAM and logging configurations.

---

## Configurability

### `spec` (object)

#### `maintenance_windows` (object)

- **`default`**
  - `start_hour` (`number`, 0–23)
  - `days_of_week` (`array of string`, min: 1, max: 7)
  - `duration` (`number`, 1–24)

#### `auto_upgrade` (`boolean`)  
Enable or disable automatic Kubernetes upgrades.

#### `cluster` (object)

- `enable_private_nodes` (`boolean`, default: `true`)
- `enable_node_auto_provisioning` (`boolean`, default: `false`)
- `enable_workload_logging` (`boolean`, default: `false`)
- `kubernetes_master_authorized_networks` (`array of string`) — CIDRs of networks allowed to access the Kubernetes master

#### `nodepools` (object)

- **`default`**
  - `enable` (`boolean`, default: `true`)
  - `instance_types` (`array of string`, **required**)
  - `root_disk_volume` (`number`, default: `100`, range: 30–500)
  - `node_lifecycle_type` (`string`, default: `SPOT`, enum: `ON_DEMAND`, `SPOT`)
  - `max_nodes` (`number`, default: `200`, range: 1–200)
  - `enable_multi_az` (`boolean`, default: `false`)
  - `enable_secure_boot` (`boolean`, default: `false`)
  - `iam.roles` (object of key-value pairs) — key-named roles with a `role` string (e.g., `roles/container.defaultNodeServiceAccount`)

- **`facets_dedicated`**
  - `enable` (`boolean`, default: `true`)
  - `instance_types` (`array of string`, default: `["n2-standard-4"]`, **required**)
  - `root_disk_volume` (`number`, default: `100`, range: 30–500)
  - `node_lifecycle_type` (`string`, default: `SPOT`, enum: `ON_DEMAND`, `SPOT`)
  - `max_nodes` (`number`, default: `200`, range: 1–200)
  - `enable_secure_boot` (`boolean`, default: `false`)
  - `iam.roles` (object of key-value pairs) — key-named roles with a `role` string

---

## Usage

To use this flavor, define a resource of kind `kubernetes_cluster` with flavor `gcp_gke` and version `0.1`. The flavor provides options to enable private GKE nodes, configure maintenance schedules, and choose lifecycle types for worker nodes (SPOT or ON_DEMAND). IAM role mappings can be provided for both default and dedicated nodepools, and you can optionally enable secure boot or multi-AZ deployment as needed. This flavor is designed to make GKE provisioning flexible, secure, and production-ready on Google Cloud.
