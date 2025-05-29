# Kubernetes Cluster Module (GCP GKE Flavor)

## Overview

The `kubernetes_cluster - gcp_gke` flavor (v0.1) enables the creation and management of Kubernetes clusters using Google Kubernetes Engine (GKE). This module provides configuration options for defining the characteristics and behavior of GKE clusters.

Supported clouds:
- GCP

## Configurability

- **Maintenance Windows**: Details for maintenance window for the Kubernetes cluster.
  - **Default**: Default maintenance window details.
    - **Start Hour**: Start hour for maintenance window.
    - **Days of Week**: Days in the week for which the maintenance should be allowed.
    - **Duration**: Duration of maintenance in hours.

- **Auto Upgrade**: Boolean to enable auto upgrade of Kubernetes cluster.

- **Cluster**: Specifications of the Kubernetes cluster.
  - **Enable Private Nodes**: Set this to true to enable private nodes.
  - **Enable Node Auto Provisioning**: Set this to true to enable node auto provisioning.
  - **Enable Workload Logging**: Set this to true to enable workload logging.
  - **Kubernetes Master Authorized Networks**: Authorized networks for Kubernetes master.

- **Nodepool Spec**: Specifications of the nodepools for the Kubernetes cluster.
  - **Facets Default Nodepool Spec**: Specifications for facets default nodepool.
    - **Enable**: Set this to true to enable default nodepool.
    - **Instance Types**: List of instance types for worker nodes.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **Enable Multi Availability Zones**: Set this to true to enable default nodepool in multi availability zones.
    - **Enable Secure Boot**: Set this to true to enable secure boot for default nodepool.
    - **IAM**: IAM specification for facets default nodepool.
      - **IAM Roles**: IAM roles to be assigned to facets default nodepool service account.
  - **Facets Dedicated Nodepool Spec**: Specifications for facets dedicated nodepool.
    - **Enable**: Set this to true to enable facets dedicated nodepool.
    - **Instance Types**: List of instance types for worker nodes.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **Enable Secure Boot**: Set this to true to enable secure boot for facets dedicated nodepool.
    - **IAM**: IAM specification for facets dedicated nodepool.
      - **IAM Roles**: IAM roles to be assigned to facets dedicated nodepool service account.

## Usage

Use this module to create and manage Kubernetes clusters using Google Kubernetes Engine (GKE). It is especially useful for:

- Defining the characteristics and behavior of GKE clusters
- Managing the deployment and execution environment of Kubernetes clusters
- Enhancing the functionality and integration of GCP-hosted applications
