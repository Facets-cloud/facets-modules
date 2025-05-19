# CloudSQL PostgreSQL Module

## Overview

The CloudSQL module provisions and manages PostgreSQL databases on Google Cloud SQL. It supports declarative configuration of PostgreSQL instances with customizable instance sizing, versioning, additional database creation, and schema management. Designed for scalable cloud workloads, it enables flexible deployment of writer and reader nodes with fine-grained control over resource allocation.

## Configurability

- **PostgreSQL versioning**: Choose from supported versions (`12.11`, `13.3`, `14.0`) to meet application requirements.  
- **Instance sizing**: Define compute capacity and storage volume for writer and reader nodes using predefined Google Cloud SQL instance types.  
- **Reader scaling**: Specify the number of reader replicas (up to 16) for improved read throughput.  
- **Multiple databases**: Provision multiple named databases during setup via a validated comma-separated list.  
- **Custom schemas**: Define and organize database schemas mapped to specific databases with enforced naming conventions.  
- **Schema validation**: Pattern validations ensure consistent and reliable schema and database naming.

## Usage

This module enables teams to deploy CloudSQL PostgreSQL instances on GCP with production-ready configurations and control over database topology and resource allocation.

Common use cases:

- Provisioning CloudSQL PostgreSQL instances for transactional and analytical workloads  
- Scaling read-heavy applications with multiple read replicas  
- Organizing database schemas for logical separation and management  
- Automating CloudSQL PostgreSQL deployments within CI/CD pipelines  
- Managing PostgreSQL infrastructure using infrastructure-as-code tools
