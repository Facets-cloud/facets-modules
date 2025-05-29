# Kubernetes Node Pool Module (AKS Flavor)

## Overview

The `kubernetes_node_pool - aks` flavor (v0.1) enables the creation and management of Kubernetes node pools using Azure Kubernetes Service (AKS). This module provides configuration options for defining the characteristics and behavior of AKS node pools.

Supported clouds:
- Azure

## Configurability

- **Instance Type**: SKU of the virtual machines used in this node pool.
- **Min Node Count**: Minimum number of nodes which should exist within this node pool.
- **Max Node Count**: Maximum number of nodes which should exist within this node pool.
- **Disk Size**: Size of the disk in GiB for nodes in this node pool.
- **Taints**: Map of Kubernetes taints which should be applied to nodes in the node pool.
  - **Taint Object**: Configuration for each taint.
    - **Key**: Taint key.
    - **Value**: Taint value.
    - **Effect**: Taint effect.
- **Labels**: Map of labels to be added to nodes in the node pool. Enter key-value pair for labels in YAML format.

## Usage

Use this module to create and manage Kubernetes node pools using Azure Kubernetes Service (AKS). It is especially useful for:

- Defining the characteristics and behavior of AKS node pools
- Managing the deployment and execution environment of Kubernetes nodes
- Enhancing the functionality and integration of Azure-hosted applications
