# MySQL Module (RDS Flavor)

## Overview

The `mysql - rds` flavor (v0.1) enables the creation and management of MySQL databases using Amazon RDS (Relational Database Service). This module provides a fully managed MySQL solution with automatic backups, patching, monitoring, and scaling capabilities, optimized for AWS cloud environments with enterprise-grade reliability.

Supported clouds:
- AWS

## Configurability

- **MySQL Version**: Amazon RDS MySQL version to deploy (supported versions: 8.0, 5.7)
- **Size Configuration**:
  - **Writer Configuration**:
    - **Instance**: RDS instance type for writer nodes (selection includes db.t4g, db.t3, and db.t2 series)
  - **Reader Configuration**:
    - **Instance**: RDS instance type for reader nodes (same instance type options as writer)
    - **Instance Count**: Number of read replica instances (0-20, allowing zero for writer-only configurations)
- **Apply Immediately**: Boolean flag to specify whether modifications are applied immediately or during the next maintenance window (default: false)

## Usage

Use this module to deploy and manage MySQL databases using Amazon RDS with comprehensive instance configuration and maintenance control. It is especially useful for:

- Implementing fully managed MySQL databases with automatic maintenance and updates
- Supporting read-heavy workloads with configurable read replicas (0-20 instances)
- Providing enterprise-grade MySQL performance with AWS optimized infrastructure
- Enabling flexible instance sizing with T-series instance types for various workload requirements
- Managing database maintenance windows and immediate configuration changes
- Leveraging automatic backups, point-in-time recovery, and monitoring capabilities
- Supporting production applications requiring high availability and durability
