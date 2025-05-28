# MongoDB Module (Atlas Flavor)

## Overview

The `mongo - atlas` flavor (v0.1) enables the creation and management of MongoDB databases using MongoDB Atlas cloud service. This module provides a managed database solution that automatically handles infrastructure provisioning, scaling, backup, and maintenance across multiple cloud providers.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **MongoDB Version**: Version of MongoDB to deploy (e.g., '7.0')
- **Size Configuration**:
  - **Instance**: Atlas instance type (e.g., M10, M20, M30)
  - **Instance Count**: Number of instances in the cluster
  - **Volume**: Storage volume size in GB
- **Region**: Geographic region for deployment (e.g., INDIA_CENTRAL)
- **Replication Specifications**: Advanced replication configuration including:
  - **Number of Shards**: Number of shards for horizontal scaling
  - **Region Configurations**: Multi-region deployment settings
  - **Electable Specifications**: Configuration for electable nodes including node count

## Usage

Use this module to deploy and manage MongoDB databases using MongoDB Atlas. It is especially useful for:

- Setting up managed MongoDB databases with automatic scaling and maintenance
- Implementing high-availability database solutions with built-in replication
- Deploying multi-region database clusters for global applications
- Providing enterprise-grade database features without infrastructure management overhead
- Supporting applications requiring NoSQL document storage with ACID transactions
- Enabling database monitoring, backup, and security features through Atlas management console
