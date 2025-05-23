# Kubernetes Node Pool – EKS Self Managed Flavor (v0.1)

## Overview

The `kubernetes_node_pool - eks_self_managed` flavor (v0.1) enables the creation and management of Kubernetes node pools specifically for Amazon EKS Self Managed clusters. This module provides configuration options for defining the characteristics and behavior of node pools.

Supported platforms:
- AWS

## Configurability

### Spec

#### `title` (`string`)

Title of the Kubernetes Node Pool.

#### `description` (`string`)

Description of the Kubernetes Node Pool for EKS Self Managed flavor.

#### `type` (`string`)

Type of the Kubernetes Node Pool configuration.

#### `properties` (`object`)

Configuration properties for the Kubernetes node pool.

##### `instance_type` (`string`)

Instance type for nodes in node pool.

- **Title**: Instance Type
- **Description**: Instance type for nodes in node pool
- **UI Placeholder**: e.g. 'm4.xlarge'

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

##### `azs` (`string`)

Comma-separated list of availability zones where worker nodes should be deployed.

- **Title**: Availability Zones
- **Description**: Comma-separated list of availability zones where worker nodes should be deployed

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

##### `ami_id` (`string`)

AMI ID of the AMI image to be used for the Kubernetes node. This should be self-owned AMI.

- **Title**: AMI ID
- **Description**: AMI ID of the AMI image to be used for the Kubernetes node. This should be self-owned AMI.

##### `ami_name_filter` (`string`)

AMI name filter for AMI image to be used for the Kubernetes node.

- **Title**: AMI Name Filter
- **Description**: AMI name filter for AMI image to be used for the Kubernetes node.

##### `ami_owner_id` (`string`)

AMI owner ID of the AMI image to be used for the Kubernetes node while using a name filter
