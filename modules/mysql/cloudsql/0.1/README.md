# MySQL Module (CloudSQL Flavor)

## Overview

The `mysql - cloudsql` flavor (v0.1) enables the creation and management of MySQL databases using Google Cloud SQL, Google Cloud Platform's fully managed relational database service. This module provides a scalable MySQL solution with high availability, automatic backups, and seamless integration with GCP services.

Supported clouds:
- GCP

## Configurability

- **MySQL Version**: Google Cloud SQL MySQL version to deploy (supported versions: 8.0, 5.7, 5.6)
- **Size Configuration**:
  - **Writer Configuration**:
    - **Instance**: Cloud SQL instance type for writer nodes (comprehensive selection including db-f1-micro, db-g1-small, db-n1-standard, db-n1-highmem, db-n1-highcpu, and db-custom series)
    - **Volume**: Storage volume size for writer nodes (format: integer with G suffix, e.g., '10G')
  - **Reader Configuration**:
    - **Instance**: Cloud SQL instance type for reader nodes (same instance type options as writer)
    - **Volume**: Storage volume size for reader nodes (format: integer with G suffix)
    - **Instance Count**: Number of read replica instances (0-20, allowing zero for writer-only configurations)

## Usage

Use this module to deploy and manage MySQL databases using Google Cloud SQL with flexible instance and storage configuration. It is especially useful for:

- Implementing managed MySQL databases with automatic maintenance and updates
- Supporting read-heavy workloads with configurable read replicas (0-20 instances)
- Providing enterprise-grade MySQL performance with Google Cloud infrastructure
- Enabling flexible instance sizing with comprehensive GCP instance type support
- Leveraging automatic backups, point-in-time recovery, and high availability features
- Integrating with Google Cloud services and IAM for comprehensive cloud-native architectures
- Scaling database performance and storage independently for optimal cost-efficiency
