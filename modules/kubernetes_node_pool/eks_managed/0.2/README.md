# Kubernetes Node Pool Module (EKS Managed Flavor)

## Overview

The `kubernetes_node_pool - eks_managed` flavor (v0.2) enables the creation and management of Kubernetes node pools using Amazon EKS Managed Node Groups. This module provides configuration options for defining the characteristics and behavior of EKS managed node pools.

Supported clouds:
- AWS

## Configurability

- **Instance Type**: Comma-separated list of instance types for nodes in the node pool.
- **Min Node Count**: Minimum number of nodes which should exist within this node pool.
- **Max Node Count**: Maximum number of nodes which should exist within this node pool.
- **Is Public**: Set this to true to deploy the node pool in public subnets.
- **Disk Size**: Size of the disk in GiB for nodes in this node pool.
- **Availability Zones**: Comma-separated list of availability zones where worker nodes should be deployed.
- **Taints**: Map of Kubernetes taints which should be applied to nodes in the node pool.
  - **Taint Object**: Configuration for each taint.
    - **Key**: Taint key.
    - **Value**: Taint value.
    - **Effect**: Taint effect.
- **Labels**: Map of labels to be added to nodes in the node pool. Enter key-value pair for labels in YAML format.
- **Capacity Type**: Lifecycle plan for worker nodes (ON_DEMAND or SPOT).
- **AMI ID**: AMI ID of the AMI image to be used for the Kubernetes node. This should be self-owned AMI.
- **AMI Name Filter**: AMI name filter for AMI image to be used for the Kubernetes node.
- **AMI Owner ID**: AMI owner ID of the AMI image to be used for the Kubernetes node while using a name filter.

## Usage

Use this module to create and manage Kubernetes node pools using Amazon EKS Managed Node Groups. It is especially useful for:

- Defining the characteristics and behavior of EKS managed node pools
- Managing the deployment and execution environment of Kubernetes nodes
- Enhancing the functionality and integration of AWS-hosted applications
