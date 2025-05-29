# Kubernetes Node Pool Module (GKE Node Pool Flavor)

## Overview

The `kubernetes_node_pool - gke_node_pool` flavor (v0.1) enables the creation and management of Kubernetes node pools using Google Kubernetes Engine (GKE). This module provides configuration options for defining the characteristics and behavior of GKE node pools.

Supported clouds:
- GCP

## Configurability

- **Instance Type**: Instance type for nodes in the node pool.
- **Min Node Count**: Minimum number of nodes which should exist within this node pool.
- **Max Node Count**: Maximum number of nodes which should exist within this node pool.
- **Is Public**: Set this to true to deploy the node pool in public subnets.
- **Disk Size**: Size of the disk in GiB for nodes in this node pool.
- **Taints**: Array of Kubernetes taints which should be applied to nodes in the node pool. Enter array of objects in YAML format.
- **Labels**: Map of labels to be added to nodes in the node pool. Enter key-value pair for labels in YAML format.
- **IAM**: IAM specification for Kubernetes node pool.
  - **IAM Roles**: IAM roles to be assigned to node pool service account.

## Usage

Use this module to create and manage Kubernetes node pools using Google Kubernetes Engine (GKE). It is especially useful for:

- Defining the characteristics and behavior of GKE node pools
- Managing the deployment and execution environment of Kubernetes nodes
- Enhancing the functionality and integration of GCP-hosted applications
