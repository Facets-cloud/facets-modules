# Kubernetes Cluster – Azure AKS Flavor (v0.1)

## Overview

The `kubernetes_cluster - azure_aks` flavor (v0.1) provides a standardized interface for provisioning and managing a **Kubernetes cluster on Microsoft Azure (AKS)**. It supports key configurations such as node pools, lifecycle types, maintenance windows, and disk types, making it easy to deploy scalable and resilient clusters in Azure.

Supported platform:
- Azure

> ⚙️ Suitable for environments that require managed Kubernetes infrastructure with nodepool flexibility and scheduled maintenance capabilities.

---

## Configurability

### `spec` (object)

#### `maintenance_windows` (object)

- **`default`**  
  - `start_hour` (`number`, 0–23)  
  - `days_of_week` (`array of string`, min: 1, max: 1)  
  - `duration` (`number`, 1–24)

#### `auto_upgrade` (`boolean`)  
Enable or disable automatic Kubernetes upgrades.

#### `nodepools` (object)

- **`default`**  
  - `enable` (`boolean`)  
  - `instance_types` (`array of string`, **required**)  
  - `root_disk_volume` (`number`, default: `100`, range: 30–500)  
  - `node_lifecycle_type` (`string`, default: `SPOT`, enum: `ON_DEMAND`, `SPOT`)  
  - `max_nodes` (`number`, default: `200`, range: 1–200)  
  - `azure_disk_type` (`string`, default: `Managed`, enum: `Managed`, `Ephemeral`)

- **`facets_dedicated`**  
  - `enable` (`boolean`)  
  - `instance_type` (`string`, default: `standard_D4as_v5`, **required**)  
  - `root_disk_volume` (`number`, default: `100`, range: 30–500)  
  - `node_lifecycle_type` (`string`, default: `SPOT`, enum: `ON_DEMAND`, `SPOT`)  
  - `max_nodes` (`number`, default: `8`, range: 1–200)  
  - `azure_disk_type` (`string`, default: `Managed`, enum: `Managed`, `Ephemeral`)

---

## Usage

To use this flavor, define a resource of kind `kubernetes_cluster` with flavor `azure_aks` and version `0.1`. You can configure cluster maintenance windows to define allowed upgrade times, toggle automatic upgrades, and provision nodepools for general and dedicated workloads. Each nodepool allows detailed settings such as disk size, instance types, lifecycle plans (spot or on-demand), and maximum node limits. This flavor is well-suited for managing AKS clusters declaratively in Azure-based environments.
