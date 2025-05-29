# Kubernetes Cluster Module (Azure AKS Flavor)

## Overview

The `kubernetes_cluster - azure_aks` flavor (v0.1) enables the creation and management of Kubernetes clusters using Azure AKS. This module provides configuration options for defining the characteristics and behavior of AKS clusters.

Supported clouds:
- Azure

## Configurability

- **Maintenance Windows**: Details for maintenance window for the Kubernetes cluster.
  - **Default**: Default maintenance window details.
    - **Start Hour**: Start hour for maintenance window.
    - **Days of Week**: Day of the week for which the maintenance should be allowed.
    - **Duration**: Duration of maintenance in hours.

- **Auto Upgrade**: Boolean to enable auto upgrade of Kubernetes cluster.

- **Nodepool Spec**: Specifications of nodepools to be created.
  - **Default Nodepool Spec**: Specification of default nodepools.
    - **Enable**: Set this to true to enable default nodepool.
    - **Instance Types**: List of instance types for worker nodes.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **Azure Disk Type**: The type of the disk which should be used by the default node pool of the Kubernetes Cluster.
  - **Facets Dedicated Nodepool Spec**: Specifications of facets dedicated nodepools.
    - **Enable**: Set this to true to enable facets dedicated nodepools.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **Instance Type**: Space-separated list of instance types for worker nodes.
    - **Azure Disk Type**: The type of the disk which should be used by the default node pool of the Kubernetes Cluster.

## Usage

Use this module to create and manage Kubernetes clusters using Azure AKS. It is especially useful for:

- Defining the characteristics and behavior of AKS clusters
- Managing the deployment and execution environment of Kubernetes clusters
- Enhancing the functionality and integration of Azure-hosted applications
