# MongoDB Atlas Flavor Documentation (v0.1)

## Overview

The `mongo - atlas` flavor (v0.1) provisions a managed MongoDB instance using **MongoDB Atlas**, a cloud-hosted database service offered by MongoDB Inc. This flavor enables seamless setup of database clusters across AWS, GCP, Azure, or Kubernetes-managed environments using the Atlas API.

It supports specifying instance sizes, regions, MongoDB versions, and high-availability configurations such as replication and sharding.

## Configurability

### Specification

- **mongodb_version** (`string`):  
  The desired MongoDB version to deploy (e.g., `"7.0"`).

- **size** (`object`):  
  Configuration related to the Atlas cluster size:
  - `instance` (`string`): The Atlas instance size (e.g., `M10`, `M20`).
  - `instance_count` (`integer`): Number of instances in the cluster (typically `1` for non-sharded deployments).
  - `volume` (`integer`): Size of disk volume in GB.

- **region** (`string`):  
  The target region in which the cluster is to be created (e.g., `INDIA_CENTRAL`).

- **replication_specs** (`array`):  
  Defines high availability and sharding configuration:
  - `num_shards` (`integer`): Number of shards (set to `1` for non-sharded).
  - `region_configs` (`array`): List of region-specific node settings.
    - `electable_specs.node_count` (`integer`): Number of electable nodes in a region (typically 3 for production-grade HA).

## Usage

This flavor is ideal when working with **MongoDB Atlas** for managed database deployments, offering:

- Quick provisioning of scalable MongoDB clusters.
- Built-in support for replication and regional high availability.
- Integration with infrastructure-as-code pipelines for environment consistency.
- Managed backups, monitoring, and SLA-backed uptime through Atlas.

Use this when you want a fully managed MongoDB database with minimal operational overhead, high scalability, and native cloud-region support.

## Cloud Providers

- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (for CI/CD orchestration only)**
