# MySQL Module (Aurora Flavor)

## Overview

The `mysql - aurora` flavor (v0.2) enables the creation and management of MySQL databases using Amazon Aurora, AWS's cloud-native relational database service. This module provides a fully managed MySQL solution with high performance, availability, and scalability, featuring comprehensive instance type selection and maintenance configuration options.

Supported clouds:
- AWS

## Configurability

- **MySQL Version**: Amazon Aurora MySQL version to deploy (e.g., '8.0')
- **Size Configuration**:
  - **Writer Configuration**:
    - **Instance**: Aurora instance type for writer nodes (comprehensive selection including db.t3, db.t4g, db.m5, db.m6g, and db.r5/r6g series)
    - **Instance Count**: Number of writer instances (1-20, minimum 1 required)
  - **Reader Configuration**:
    - **Instance**: Aurora instance type for reader nodes (same instance type options as writer)
    - **Instance Count**: Number of read replica instances (0-20, allowing zero for writer-only configurations)
- **Apply Immediately**: Boolean flag to specify whether modifications are applied immediately or during the next maintenance window (default: false)

## Usage

Use this module to deploy and manage MySQL databases using Amazon Aurora with flexible instance configuration and maintenance control. It is especially useful for:

- Implementing high-availability MySQL databases with automatic failover capabilities
- Supporting read-heavy workloads with configurable read replicas (0-20 instances)
- Providing enterprise-grade MySQL performance with Aurora's storage engine optimizations
- Enabling flexible instance sizing with comprehensive AWS instance type support
- Managing database maintenance windows and immediate configuration changes
- Supporting mission-critical applications requiring high durability and availability
- Scaling database performance with writer and reader node configurations
