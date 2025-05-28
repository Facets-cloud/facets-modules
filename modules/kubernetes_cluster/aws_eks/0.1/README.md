# Kubernetes Cluster Module (AWS EKS Flavor)

## Overview

The `kubernetes_cluster - aws_eks` flavor (v0.1) enables the creation and management of Kubernetes clusters using Amazon EKS. This module provides configuration options for defining the characteristics and behavior of EKS clusters.

Supported clouds:
- AWS

## Configurability

- **Cluster Spec**: Specifications of the cluster to be created.
  - **CloudWatch Log Retention Days**: Retention period in days for CloudWatch Logs generated for this EKS cluster.
  - **Public CIDR Whitelist**: Comma-separated list of CIDR blocks which can access the Amazon EKS public API server endpoint.
  - **KMS Keys**: Specification of AWS KMS.
    - **Deletion Window**: Waiting period in days after which KMS keys are deleted.
    - **Enable Rotation**: Specifies whether key rotation is enabled.
    - **Rotation Period**: Specifies rotation period for KMS in days.
  - **Default Reclaim Policy**: The reclaim policy for the default storage class in a Kubernetes cluster.

- **Nodepool Spec**: Specifications of nodepools to be created.
  - **Default Nodepool Spec**: Specification of default nodepools.
    - **Instance Types**: Space-separated list of instance types for worker nodes.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **AMI ID**: AMI ID of the AMI image to be used for the Kubernetes node.
    - **AMI Name Filter**: AMI name filter for AMI image to be used for the Kubernetes node.
    - **AMI Owner ID**: AMI owner ID of the AMI image to be used for the Kubernetes node while using a name filter.
  - **Facets Dedicated Nodepool Spec**: Specifications of facets dedicated nodepools.
    - **Enable**: Set this to true to enable facets dedicated nodepools.
    - **Root Disk Volume**: Disk size in GiB for worker nodes.
    - **Node Lifecycle Type**: Select lifecycle plan for worker nodes.
    - **Max Nodes**: Maximum number of worker nodes in the node pool.
    - **Instance Type**: Instance type of facets dedicated node pool.
    - **AMI ID**: AMI ID of the AMI image to be used for the Kubernetes node.
    - **AMI Name Filter**: AMI name filter for AMI image to be used for the Kubernetes node.
    - **AMI Owner ID**: AMI owner ID of the AMI image to be used for the Kubernetes node while using a name filter.
  - **Ondemand Fallback Nodepool Spec**: Specifications of ondemand fallback nodepool.
    - **Enable**: Boolean to enable ondemand fallback nodepool.
    - **Instance Type**: Instance type.
    - **Max Nodes**: Maximum number of nodes in nodepool.
    - **AMI ID**: AMI ID of the AMI image to be used for the Kubernetes node.
    - **AMI Name Filter**: AMI name filter for AMI image to be used for the Kubernetes node.
    - **AMI Owner ID**: AMI owner ID of the AMI image to be used for the Kubernetes node while using a name filter.

- **Kubernetes Cluster Tags**: Enter key-value pair for tags, to be added to the cluster, in YAML format.

- **Addons**: Specifications of addons to be installed.
  - **Addon Name**: Configuration for each addon.
    - **Enable**: Set this to true to enable the addon.
    - **Configuration Values**: Configuration values for the addon.
    - **Resolve Conflicts**: Set this to true to resolve conflicts.
    - **Addon Version**: Version of the addon.
    - **Addon Tags**: Enter key-value pair for tags, to be added to the addon, in YAML format.
    - **Preserve**: Set this to true to preserve the addon.
    - **Service Account Role ARN**: Service account for the addon.

## Usage

Use this module to create and manage Kubernetes clusters using Amazon EKS. It is especially useful for:

- Defining the characteristics and behavior of EKS clusters
- Managing the deployment and execution environment of Kubernetes clusters
- Enhancing the functionality and integration of AWS-hosted applications
