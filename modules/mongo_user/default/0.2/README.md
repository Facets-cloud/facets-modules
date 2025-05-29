# MongoDB User Module (Default Flavor)

## Overview

The `mongo_user - default` flavor (v0.2) enables the creation and management of MongoDB users through Kubernetes Custom Resource Definitions (CRDs) using the MongoDB Auth Operator. This module provides comprehensive user management capabilities with fine-grained permission control and role-based access for MongoDB databases in Kubernetes environments.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Input Dependencies**:
  - **Kubernetes Details**: Kubernetes cluster where the CRD for managing MongoDB users will be created
  - **MongoDB Auth Operator Details**: MongoDB Auth Operator responsible for creating MongoDB users
  - **Mongo Details**: MongoDB instance where the user needs to be created

- **Database**: Target database name for user operations

- **Permissions**: Collection of permission configurations with the following properties:
  - **Permission**: Comma-separated MongoDB permissions (e.g., createCollection, listCollections, find, update, insert)
  - **Database**: Database name for which permissions should be granted
  - **Collection**: Collection name within the database (optional for database-level permissions)
  - **Cluster**: Boolean flag indicating cluster-level permissions

- **Mongo User Configuration**:
  - **Username**: Username for the MongoDB user
  - **Password**: Password for the MongoDB user
  - **Custom Data**: Additional user metadata in YAML format
  - **Mechanisms**: Authentication mechanisms for the user
  - **DB Roles**: Database roles assigned to the user in YAML format
  - **Roles to Role**: Role-to-role mappings for the user

## Usage

Use this module to create and manage MongoDB users through Kubernetes operators with comprehensive access control. It is especially useful for:

- Creating MongoDB users via Kubernetes CRDs with operator-based management
- Implementing fine-grained permission control at database and collection levels
- Managing user authentication and authorization through MongoDB Auth Operator
- Supporting role-based access control (RBAC) for MongoDB databases
- Integrating MongoDB user management with Kubernetes-native workflows
- Providing declarative user management for cloud-native MongoDB deployments
- Enabling automated user provisioning and lifecycle management in Kubernetes environments
