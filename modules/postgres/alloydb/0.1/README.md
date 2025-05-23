# AlloyDB for PostgreSQL Module

## Overview

The AlloyDB module provisions and manages PostgreSQL databases on Google Cloud’s AlloyDB. It supports declarative configuration of PostgreSQL clusters with customizable instance sizing, versioning, additional database creation, and schema management. Designed for enterprise-grade workloads, it enables high availability, scalability, and cloud-native performance optimization.

## Configurability

- **PostgreSQL versioning**: Choose from supported versions (`12.11`, `13.3`, `14.0`) to match application requirements.  
- **Instance sizing**: Define compute capacity for writer and reader nodes with fine-grained control over CPU cores.  
- **Reader scaling**: Specify the number of reader replicas (up to 10) for read scalability.  
- **Multiple databases**: Provision multiple named databases during setup via a comma-separated list.  
- **Custom schemas**: Define and organize database schemas mapped to specific databases.  
- **Schema validation**: Enforced naming conventions and pattern validations ensure reliable deployments.

## Usage

This module allows teams to deploy AlloyDB clusters on GCP with production-ready configurations and strong control over resource allocation and data organization.

Common use cases:

- Provisioning AlloyDB clusters for transactional and analytical workloads  
- Scaling read-heavy workloads with multiple reader replicas  
- Organizing logical database boundaries with schemas  
- Automating GCP-native PostgreSQL deployment in CI/CD pipelines  
- Managing PostgreSQL at scale with infrastructure-as-code
