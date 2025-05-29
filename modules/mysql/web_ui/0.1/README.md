# MySQL Web UI Module (K8s Flavor)

## Overview

The `mysql_web - k8s` flavor (v0.1) provides a web-based graphical user interface for MySQL database management in Kubernetes environments. This module deploys a containerized MySQL administration tool that enables users to interact with MySQL databases through a user-friendly web interface, supporting database operations, queries, and administration tasks.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Input Dependencies**:
  - **MySQL Instance**: MySQL database instance that the web UI will connect to and manage

- **Metadata Configuration**:
  - **Namespace**: Kubernetes namespace where the MySQL Web UI should be deployed (default: default)

- **MySQL Web Version**: Version of the MySQL Web UI to deploy (e.g., '5.2.1-debian-12-r35')

- **Size Configuration**:
  - **CPU**: CPU cores required (format: number 1-32 or 1m-32000m)
  - **Memory**: Memory required (format: 1Gi-64Gi or 1Mi-64000Mi)
  - **CPU Limit**: Maximum CPU utilization limit (optional)
  - **Memory Limit**: Maximum memory utilization limit (optional)

## Usage

Use this module to deploy a web-based administration interface for MySQL databases in Kubernetes environments. It is especially useful for:

- Providing a user-friendly graphical interface for MySQL database management
- Enabling database administrators to perform operations without command-line tools
- Supporting database query execution and result visualization through a web browser
- Facilitating database schema management and data manipulation tasks
- Offering secure web-based access to MySQL databases with namespace isolation
- Supporting development and testing workflows with easy database access
- Enabling team collaboration on database management tasks through a shared web interface
