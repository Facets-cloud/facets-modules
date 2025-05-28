# MySQL Module (Flexible Server Flavor)

## Overview

The `mysql - flexible_server` flavor (v0.1) enables the creation and management of MySQL databases using Azure Database for MySQL Flexible Server. This module provides a fully managed MySQL solution optimized for Azure cloud environments, offering high performance, scalability, and enterprise-grade security with flexible configuration options.

Supported clouds:
- Azure

## Configurability

- **MySQL Version**: Azure MySQL Flexible Server version to deploy (supported versions: 5.7, 8.0.21)
- **Size Configuration**:
  - **Writer Configuration**:
    - **Instance**: Azure instance type for writer nodes (comprehensive selection including GP_Standard_D series, GP_Standard_E series, and Standard_B series)
  - **Reader Configuration**:
    - **Instance**: Azure instance type for reader nodes (same instance type options as writer)
    - **Instance Count**: Number of read replica instances (0-20, allowing zero for writer-only configurations)

## Usage

Use this module to deploy and manage MySQL databases using Azure Database for MySQL Flexible Server with comprehensive instance type selection. It is especially useful for:

- Implementing managed MySQL databases with Azure's enterprise-grade security and compliance
- Supporting read-heavy workloads with configurable read replicas (0-20 instances)
- Providing high-performance MySQL solutions with Azure's optimized infrastructure
- Enabling flexible instance sizing with General Purpose (GP_Standard_D/E) and Burstable (Standard_B) series
- Leveraging automatic backups, point-in-time recovery, and high availability features
- Integrating with Azure services and Active Directory for comprehensive cloud-native architectures
- Scaling database performance with independent writer and reader configurations
