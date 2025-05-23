# Kubernetes Node Pool – AKS Flavor (v0.1)

## Overview

The `kubernetes_node_pool - aks` flavor (v0.1) enables the creation and management of Kubernetes node pools specifically for Azure Kubernetes Service (AKS). This module provides configuration options for defining the characteristics and behavior of node pools.

Supported platforms:
- Azure

## Configurability

### Spec

#### `title` (`string`)

Title of the Kubernetes Node Pool.

#### `description` (`string`)

Description of the Kubernetes Node Pool for AKS flavor.

#### `type` (`string`)

Type of the Kubernetes Node Pool configuration.

#### `properties` (`object`)

Configuration properties for the Kubernetes node pool.

##### `instance_type` (`string`)

SKU of the virtual machines used in this node pool.

- **Title**: Instance Type
- **Description**: SKU of the virtual machines used in this node pool
- **UI Placeholder**: Eg. Standard_D4a_v4

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

##### `disk_size` (`string`)

Size of the Disk in GiB for node in this node pool.

- **Title**: Disk Size
- **Description**: Size of the Disk in GiB for node in this node pool
- **Pattern**: '\b((5[0-9]G)|([6-9][0-9]G)|([1-9][0-9][0-9]G)|(1000G))\b'
- **UI Placeholder**: "eg. 50G"
- **UI Error Message**: "Value doesn't match the format eg. 50G. Minimum is 50G and max is 1000G"

##### `taints` (`object`)

Map of Kubernetes taints which should be applied to nodes in the node pool.

- **Title**: Taints
- **Description**: Map of Kubernetes taints which should be applied to nodes in the node pool
- **Pattern Properties**:
  - **Type**: `object`
  - **Title**: Taint Object
  - **Key Pattern**: "^[a-z][a-z0-9-_]*$"
  - **Properties**:
    - **key** (`string`): Taint Key.
      - **Title**: Taint Key
      - **Description**: Taint Key
      - **UI Placeholder**: CriticalAddonsOnly
    - **value** (`string`): Taint Value.
      - **Title**: Taint Value
      - **Description**: Taint Value
      - **UI Placeholder**: "true"
    - **effect** (`string`): Taint Effect.
      - **Title**: Taint Effect
      - **Description**: Taint Effect
      - **UI Placeholder**: NoSchedule

##### `labels` (`object`)

Map of labels to be added to nodes in node pool.

- **Title**: Labels
- **Description**: "Map of labels to be added to nodes in node pool. Enter key-value pair for labels in YAML format. Eg. key: value (provide a space after ':' as expected in the YAML format)"
- **UI Placeholder**: "Eg. key1: value1"
- **UI YAML Editor**: `true`

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

Use this module to create and manage Kubernetes node pools specifically for Azure Kubernetes Service (AKS). It is especially useful for:

- Defining the characteristics and behavior of node pools
- Managing the scaling and resources of node pools
- Enhancing the performance and reliability of Kubernetes clusters
