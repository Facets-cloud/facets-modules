# PostgreSQL Kubernetes Module

## Overview

The PostgreSQL Kubernetes module provisions and manages PostgreSQL databases deployed on Kubernetes clusters across multiple cloud providers including AWS, Azure, GCP, and native Kubernetes environments. It supports declarative configuration of PostgreSQL versions, resource sizing for writer and reader nodes, scaling of read replicas, and setup of multiple databases and schemas. This module is designed for scalable, cloud-native PostgreSQL deployments with flexible configuration and resource control.

## Configurability

- **PostgreSQL versioning**: Select from a range of supported PostgreSQL versions (e.g., `9.6.9`, `12.9.0`, `15.3.0`, `16.4.0`) to fit your application compatibility needs.  
- **Instance sizing**: Configure CPU and memory requests and limits separately for writer and reader nodes, with persistent storage volume sizing.  
- **Reader scaling**: Define the number of read replica instances (up to 10) to scale read operations and improve performance.  
- **Multiple databases**: Create multiple named databases on deployment by specifying a comma-separated list.  
- **Custom schemas**: Map schemas to specific databases to organize data logically within your PostgreSQL deployment.  
- **Validation and naming conventions**: Enforced patterns and limits ensure resource configurations and database/schema names comply with Kubernetes and PostgreSQL best practices.

## Usage

This module empowers teams to deploy and manage PostgreSQL on Kubernetes clusters with flexible resource allocation, version control, and data organization.

Typical use cases include:

- Deploying PostgreSQL clusters on Kubernetes for cloud-agnostic workloads  
- Scaling read-heavy database applications with multiple read replicas  
- Creating isolated logical databases and schemas for multi-tenant or modular applications  
- Automating PostgreSQL deployment and upgrades via Infrastructure-as-Code (IaC) pipelines  
- Ensuring resource limits and naming conventions for robust and compliant database operations
