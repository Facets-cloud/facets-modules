# MySQL Module (Aurora Flavor)

## Overview

The `mysql - aurora` flavor (v0.1) enables the creation and management of MySQL databases using Amazon Aurora, AWS's cloud-native relational database service. This module provides a fully managed MySQL solution with high performance, availability, and scalability, optimized for cloud workloads with automatic scaling and multi-AZ deployment capabilities.

Supported clouds:
- AWS

## Configurability

- **MySQL Version**: Amazon Aurora MySQL version to deploy (e.g., '8.0.mysql_aurora.3.02.0')
- **Size Configuration**:
  - **Writer Configuration**:
    - **Instance**: Aurora instance type for writer nodes (e.g., db.t4g.medium)
    - **Instance Count**: Number of writer instances
  - **Reader Configuration**:
    - **Instance Count**: Number of read replica instances
    - **Instance**: Aurora instance type for reader nodes (e.g., db.t4g.medium)

## Usage

Use this module to deploy and manage MySQL databases using Amazon Aurora for high-performance, scalable database solutions. It is especially useful for:

- Implementing high-availability MySQL databases with automatic failover capabilities
- Supporting read-heavy workloads with configurable read replicas
- Providing enterprise-grade MySQL performance with Aurora's storage engine optimizations
- Enabling automatic scaling and serverless database operations
- Supporting mission-critical applications requiring high durability and availability
- Integrating with AWS ecosystem services for comprehensive cloud-native architectures
