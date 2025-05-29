# MongoDB Module (DocumentDB Flavor)

## Overview

The `mongo - documentdb` flavor (v0.1) enables the creation and management of MongoDB-compatible databases using AWS DocumentDB service. This module provides a fully managed document database service that is compatible with MongoDB workloads, offering the performance, scalability, and availability of AWS cloud infrastructure.

Supported clouds:
- AWS

## Configurability

- **MongoDB Version**: Version of MongoDB compatibility to use (e.g., '5.0')
- **Size Configuration**:
  - **Instance Count**: Number of instances in the DocumentDB cluster
  - **Instance**: AWS DocumentDB instance type (e.g., db.r4.large, db.r5.large)

## Usage

Use this module to deploy and manage MongoDB-compatible databases using AWS DocumentDB. It is especially useful for:

- Migrating existing MongoDB workloads to a fully managed AWS service
- Implementing scalable document databases with AWS native integration
- Providing MongoDB-compatible APIs with enterprise-grade security and compliance
- Supporting applications requiring document storage with automatic backup and patching
- Enabling high-performance database operations with AWS optimized infrastructure
- Integrating with other AWS services for comprehensive cloud-native architectures
