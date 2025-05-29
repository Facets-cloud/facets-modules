# CloudSQL PostgreSQL Module (v0.1)

## Overview

The CloudSQL PostgreSQL v0.1 module provisions and manages PostgreSQL instances on **Google Cloud SQL**. It provides configurable instance sizing for both writer and reader nodes, including storage volume, and supports specifying the PostgreSQL version to match application needs.

## Configurability

- **PostgreSQL Versioning**: Select the PostgreSQL version (e.g., `12.11`) to deploy.
- **Instance Sizing**:
  - **Writer**: Configure the instance type and storage volume for the primary writer node.
  - **Reader**: Define the number of read replicas, their instance type, and storage volume for scaling read workloads.
- **Cloud Provider**: Supports deployment on Google Cloud Platform (GCP) only.

## Usage

Configure the PostgreSQL version, writer and reader instance types with volumes, and the reader instance count in the `spec` section to deploy a CloudSQL PostgreSQL cluster tailored to your workload requirements.
