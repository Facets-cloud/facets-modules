# MongoDB User Module (Default Flavor)

## Overview

The `mongo_user - default` flavor (v0.1) enables the creation and management of MongoDB users with comprehensive permission and role configurations. This module provides fine-grained access control for MongoDB databases, allowing you to define user permissions, roles, and authentication restrictions across multiple cloud environments.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Endpoint**: MongoDB connection string with authentication details
- **Database**: Target database for user operations
- **Permissions**: Collection of permission sets with the following properties:
  - **Permission**: Specific MongoDB permissions (e.g., createCollection, listCollections, find, update, insert)
  - **Database**: Database scope for the permissions
  - **Collection**: Collection scope for permissions (empty for database-level permissions)
  - **Cluster**: Boolean flag indicating cluster-level permissions
- **Advanced Configuration**:
  - **Role Configuration**: Advanced role management including database roles and role-to-role mappings
  - **User Configuration**: Comprehensive user settings including:
    - **Authentication Restrictions**: IP-based access control with client source and server address restrictions
    - **Username and Password**: User credentials
    - **Custom Data**: Additional user metadata (e.g., employeeID, profile)
    - **Mechanisms**: Authentication mechanisms (e.g., SCRAM-SHA-1)
    - **Database Roles**: User-specific database role assignments
    - **Role Mappings**: Additional role-to-role relationships

## Usage

Use this module to create and manage MongoDB users with sophisticated access control and security configurations. It is especially useful for:

- Creating MongoDB users with granular permission control at database and collection levels
- Implementing role-based access control (RBAC) for MongoDB databases
- Setting up authentication restrictions based on IP addresses and network segments
- Managing user credentials and custom metadata for organizational tracking
- Configuring cluster-level permissions for administrative users
- Supporting multi-tenant applications with isolated user access patterns
- Implementing security compliance requirements for database access control
