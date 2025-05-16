# MongoDB User Flavor Documentation

## Overview

The `mongo_user - default` flavor is used to create and manage MongoDB users within supported cloud or Kubernetes environments. It allows you to define database credentials, assign fine-grained permissions, and specify advanced authentication and role configurations.

## Configurability

### Basic Configuration

- **endpoint**: MongoDB connection URI with placeholder for credentials and host information.
- **database**: The default database where the user operates.
- **permissions**: Defines the user's access level at database or collection level.
  - `permission`: Comma-separated MongoDB privileges like `find`, `insert`, `update`, etc.
  - `database`: Name of the target database.
  - `collection`: Optional name of the target collection.
  - `cluster`: Boolean flag indicating whether the permission includes cluster-level privileges.

### Advanced Configuration (`advanced.mongo_user`)

- **user**:
  - `username` and `password`: Credentials for MongoDB authentication.
  - `customData`: Metadata associated with the user (e.g., `employeeID`, `profile`).
  - `mechanisms`: Authentication mechanism (e.g., `SCRAM-SHA-1`).
  - `dbRoles`: Custom database roles assigned directly to the user.
  - `rolesToRole`: Inherited role mappings.
  - `authenticationRestrictions`: Optional security constraints:
    - `clientSource`: Allowed source IPs.
    - `serverAddress`: Allowed server IPs.

- **role**:
  - `dbRoles`: Custom roles defined for specific databases.
  - `rolesToRole`: Inherited or composite roles assigned to the user's role.

## Usage

Use this flavor to define and manage MongoDB user accounts programmatically with strict control over database access, authentication mechanisms, and role bindings. It is ideal for scenarios requiring:

- Multi-tenant user provisioning
- Role-based access control (RBAC)
- Security enforcement through authentication restrictions
- Integration with automation pipelines for consistent and secure MongoDB user management

## Cloud Providers

- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (Generic)**
