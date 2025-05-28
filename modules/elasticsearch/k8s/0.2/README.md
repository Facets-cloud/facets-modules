# Elasticsearch - Kubernetes Flavor (v0.2)

## Overview

This module provisions Elasticsearch on Kubernetes with extended configurability for both data and client nodes. It supports deployment across major cloud providers including GCP, Kubernetes native clusters, Azure, and AWS. The configuration allows fine-grained resource allocation for CPU, memory, storage volume, and instance count, separately for data and client node types. Namespace deployment targeting is also supported via metadata.

## Configurability

- **Namespace:** Defines the Kubernetes namespace where Elasticsearch will be deployed. Defaults to `default` if not specified.
- **Elasticsearch Version:** Select from supported versions to ensure compatibility and feature support.
- **Data Node Sizing:**  
  - CPU and CPU Limit: Specify required CPU cores and maximum CPU limit with validation to prevent inconsistencies.  
  - Memory and Memory Limit: Define required and maximum memory per node with format and limit checks.  
  - Volume: Storage size per data node with validation pattern.  
  - Instance Count: Number of data node instances to deploy with enforced min and max limits.  
- **Client Node Sizing:**  
  - CPU and CPU Limit: Similar controls for client nodes to optimize query and ingestion load.  
  - Memory and Memory Limit: Configurable with validation analogous to data nodes.  
  - Volume: Storage size for client nodes with pattern validation.  
  - Instance Count: Number of client node instances with constraints.  

All sizing parameters include UI validation annotations for better user experience and error handling in configuration interfaces.

## Usage

Users should specify the desired Elasticsearch version along with sizing details for both data and client nodes. The configuration must include CPU, memory, volume, and instance counts for data nodes; client node sizing is optional but recommended for optimized deployments. Namespace can be set to deploy Elasticsearch in the appropriate Kubernetes scope. The module enforces constraints on resource requests and limits to maintain cluster stability and resource efficiency.
