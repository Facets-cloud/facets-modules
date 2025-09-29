# GCP Kubernetes Node Fleet Module

## Overview

This module manages multiple Kubernetes node pools as a fleet for Google Kubernetes Engine (GKE) clusters. It supports creating and configuring multiple node pools simultaneously with different specifications, enabling flexible workload placement and resource optimization. Designed for GCP cloud environments.

## Configurability

- **node_pools**   
  Map of node pool names to their configurations. Each key represents a node pool name with its specific configuration settings.

  - **instance_type**   
    Instance type for nodes in the node pool. Example: `e2-standard-2`, `n2-standard-4`.

  - **min_node_count**   
    Minimum number of nodes which should exist within this node pool. Range: 0-100.

  - **max_node_count** 
    Maximum number of nodes which should exist within this node pool. Range: 0-100.

  - **is_public** 
    Set this to true to deploy the node pool in public subnets, giving nodes external IP addresses.

  - **disk_size** 
    Size of the disk in GiB for each node in this node pool. Range: 50-1000 GiB.

  - **disk_type** 
    Type of disk for the nodes. Examples: `pd-standard`, `pd-ssd`, `pd-balanced`. Fully customizable.

  - **type** 
    Type of nodes to provision. Examples: `ondemand`, `spot`. Fully customizable.

  - **azs** 
    List of availability zones where nodes can be created. Environment-specific override. Example: `us-central1-a`, `us-central1-b`.

  - **iam**   
    IAM specification for node pool service accounts, including role assignments and permissions.

- **labels**  
  Map of labels to be added to all nodes in the fleet. Enter key-value pairs in YAML format. Applied across all node pools in the fleet.

- **taints** 
  Array of Kubernetes taints applied to all nodes in the fleet. Defines scheduling restrictions for pods. Environment-specific override.

## Usage

Use this module to deploy and manage multiple node pools within a GKE cluster as a cohesive fleet. Configure different node pools for various workload types, such as compute-intensive tasks using high-performance instances or cost-optimized workloads using spot instances. The fleet approach enables centralized management of node pool configurations while maintaining flexibility for diverse application requirements.