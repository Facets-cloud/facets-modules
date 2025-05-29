# Postgres RDS Module (v0.1)

## Overview

The Postgres RDS v0.1 module provisions and manages PostgreSQL databases on AWS RDS, offering flexible version selection and instance sizing for both writer and reader nodes. It supports deployment of scalable, highly available PostgreSQL clusters with customizable database and schema creation, along with advanced parameter tuning for optimized performance.

## Configurability

- **PostgreSQL versioning**: Choose from supported PostgreSQL versions (`12` through `16`) to ensure compatibility and leverage new features.  
- **Writer configuration**: Select from a wide range of AWS RDS instance types to match workload needs for the primary writer node.  
- **Reader configuration**: Provision one or more reader instances with customizable instance types and count to scale read capacity and improve availability.  
- **Database and schema management**: Define multiple database names and additional schemas within databases for flexible data organization.  
- **Advanced tuning**: Configure fine-grained RDS parameters separately for writer and reader instances, with options for immediate or pending-reboot application.  
- **Cloud provider**: Designed specifically for AWS, leveraging RDS features for managed PostgreSQL services.

## Usage

This module is well suited for teams deploying PostgreSQL workloads on AWS using infrastructure-as-code tools, enabling reliable and repeatable provisioning with scalable performance characteristics.

Common use cases:

- Deploying managed PostgreSQL clusters for transactional and analytical workloads  
- Scaling read operations with configurable read replicas  
- Automating multi-database and schema setup  
- Fine-tuning database instance parameters for workload optimization  
- Integrating PostgreSQL provisioning into CI/CD pipelines for cloud-native applications  
