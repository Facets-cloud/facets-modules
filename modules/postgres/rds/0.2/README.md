# Postgres RDS Module (v0.2)

## Overview

The Postgres RDS v0.2 module provisions and manages PostgreSQL databases on AWS using RDS within ECS environments. It supports fine-grained control over PostgreSQL versioning, instance sizing for writer and reader nodes, and advanced database schema management with parameter tuning for optimized performance.

## Configurability

- **PostgreSQL versioning**: Choose from supported versions `12` through `16` for compatibility and feature needs.  
- **Writer configuration**: Select the instance type for the primary writer node from a comprehensive list of AWS RDS instance types (e.g., `db.t4g.medium`, `db.r6i.large`, etc.).  
- **Reader configuration**: Configure reader instances with selectable instance types and specify the number of reader replicas to scale read operations.  
- **Database names**: Define a list of database names to be created on the cluster.  
- **Additional schemas**: Provide a map of additional database schemas to create within specified databases for flexible data organization.  
- **Advanced tuning**: Specify advanced RDS parameters independently for writer and reader instances, with support for immediate or pending-reboot application modes.

## Usage

This module is ideal for AWS users who want to deploy scalable, managed PostgreSQL clusters in ECS contexts with infrastructure-as-code. It enables repeatable, customizable database provisioning including multi-instance scaling and schema setup.

Common use cases:

- Deploying AWS RDS PostgreSQL clusters with precise version control  
- Scaling write and read workloads with configurable instance types and replica counts  
- Automating multi-database and schema creation  
- Applying advanced database parameters for performance tuning  
- Integrating PostgreSQL provisioning in cloud-native CI/CD pipelines
