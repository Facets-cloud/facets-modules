# Kubernetes Node Pool – GKE Node Pool Flavor (v0.1)

## Overview

The `kubernetes_node_pool - gke_node_pool` flavor (v0.1) enables the creation and management of Kubernetes node pools specifically for Google Kubernetes Engine (GKE). This module provides configuration options for defining the characteristics and behavior of node pools.

Supported platforms:
- GCP

## Configurability

### Spec

#### `title` (`string`)

Title of the Kubernetes Node Pool.

#### `description` (`string`)

Description of the Kubernetes Node Pool for GKE Node Pool flavor.

#### `type` (`string`)

Type of the Kubernetes Node Pool configuration.

#### `properties` (`object`)

Configuration properties for the Kubernetes node pool.

##### `instance_type` (`string`)

Instance type for nodes in node pool.

- **Title**: Instance Type
- **Description**: Instance type for nodes in node pool
- **UI Placeholder**: e.g. 'e2-standard-2'

##### `min_node_count` (`number`)

Minimum number of nodes which should exist within this node pool.

- **Title**: Min Node Count
- **Description**: Minimum number of nodes which should exist within this node pool
- **Minimum**: 0
- **Maximum**: 100

##### `max_node_count` (`number`)

Maximum number of nodes which should exist within this node pool.

- **Title**: Max Node Count
- **Description**: Maximum number of nodes which should exist within this node pool
- **Minimum**: 0
- **Maximum**: 100

##### `is_public` (`boolean`)

Set this to true to deploy the node pool in public subnets.

- **Title**: Is Public
- **Description**: Set this to true to deploy the node pool in public subnets

##### `disk_size` (`number`)

Size of the Disk in GiB for node in this node pool.

- **Title**: Disk Size
- **Description**: Size of the Disk in GiB for node in this node pool
- **Minimum**: 50
- **Maximum**: 1000

##### `taints` (`object`)

Array of Kubernetes taints which should be applied to nodes in the node pool.

- **Title**: Taints
- **Description**: "Array of Kubernetes taints which should be applied to nodes in the node pool. Enter array of object in YAML format. Eg. \n- key: special \nvalue: \"true\"\neffect: PreferNoSchedule.\nSet this to [] if no taints are required."
- **UI YAML Editor**: `true`
- **UI Placeholder**: "Eg. \n- key: CriticalAddonsOnly \nvalue: \"true\"\neffect: NoSchedule"

##### `labels` (`object`)

Map of labels to be added to nodes in node pool.

- **Title**: Labels
- **Description**: "Map of labels to be added to nodes in node pool. Enter key-value pair for labels in YAML format. Eg. key: value (provide a space after ':' as expected in the YAML format)"
- **UI Placeholder**: "Eg. key1: value1"
- **UI YAML Editor**: `true`

##### `iam` (`object`)

IAM specification for Kubernetes node pool.

- **Title**: IAM
- **Description**: IAM specification for Kubernetes node pool
- **Properties**:
  - **roles** (`object`): IAM roles to be assigned to node pool service account.
    - **Title**: IAM Roles
    - **Description**: IAM roles to be assigned to node pool service account
    - **Pattern Properties**:
      - **Title**: Key Name For Role
      - **Description**: Key name for role
      - **Type**: `object`
      - **Key Pattern**: "^[a-zA-Z][a-zA-Z0-9_.-]*$"
      - **Properties**:
        - **role** (`string`): Role to be added to the node pool service account.
          - **Title**: Role
          - **Description**: Role to be added to the node pool service account
          - **UI Placeholder**: e.g. roles/container.defaultNodeServiceAccount
      - **UI Error Message**: Key name should start with an alphabet and should contain alphanumeric characters with allowed special characters like underscore, period, and hyphen

#### `required` (`array`)

List of required properties.

- **Required**:
  - `instance_type`
  - `min_node_count`
  - `max_node_count`
  - `disk_size`
  - `taints`
  - `labels`

---

## Usage

Use this module to create and manage Kubernetes node pools specifically for Google Kubernetes Engine (GKE). It is especially useful for:

- Defining the characteristics and behavior of node pools
- Managing the scaling and resources of node pools
- Enhancing the performance and reliability of Kubernetes clusters
