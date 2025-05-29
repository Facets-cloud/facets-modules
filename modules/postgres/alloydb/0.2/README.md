# AlloyDB for PostgreSQL Module (v0.2)

## Overview

The AlloyDB v0.2 module provisions and manages PostgreSQL databases on Google Cloud’s AlloyDB with enhanced configuration support. It enables deployment of high-performance, cloud-native PostgreSQL clusters with versioning, compute sizing, and optional read replica setup for scalable, fault-tolerant architectures.

## Configurability

- **PostgreSQL versioning**: Select from supported PostgreSQL versions (e.g., `12.11`) to ensure compatibility and performance tuning.  
- **Writer configuration**: Define compute requirements (CPU cores) for the primary writer instance.  
- **Reader configuration**: Provision reader replicas with customizable CPU and instance count for read scalability and availability.  
- **Cloud-native**: Built to leverage GCP’s AlloyDB features with declarative provisioning.

## Usage

This module is ideal for teams deploying PostgreSQL workloads in AlloyDB environments using infrastructure-as-code for reliable, repeatable setups.

Common use cases:

- Deploying PostgreSQL clusters for transactional applications  
- Scaling read operations with managed reader instances  
- Automating database provisioning in CI/CD workflows  
- Leveraging AlloyDB’s high availability and performance benefits on GCP
