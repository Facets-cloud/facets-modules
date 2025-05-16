# MongoDB User Flavor Documentation (v0.2)

## Overview

The `mongo_user - default` flavor (v0.2) provides a way to declaratively define MongoDB users in environments backed by a MongoDB Auth Operator. It builds on the earlier version by introducing structured input dependencies, and is designed to work in Kubernetes-based infrastructures orchestrated through cloud-native tooling.

This module allows for user creation with database-specific permissions, cluster-level roles, and custom authentication mechanisms.

## Configurability

### Inputs

- **kubernetes_details**: Specifies the Kubernetes cluster where the MongoDB CRDs will be managed.
- **mongodb_auth_operator_details**: Reference to the MongoDB Auth Operator instance managing user lifecycle.
- **mongo_details**: Reference to the actual MongoDB instance where users will be provisioned.

### Specification

- **database**: Name of the default MongoDB database associated with the user.

- **permissions**: A map of permission blocks that define granular access for the user.
  - Each permission block includes:
    - `permission`: Comma-separated list of actions (e.g., `find,insert`).
    - `database`: Target database.
    - `collection`: Optional target collection.
    - `cluster`: Boolean flag for cluster-level permissions.

- **mongo_user**: Encapsulates full user identity and access roles.
  - `user`:
    - `username`: Name of the MongoDB user.
    - `password`: Password for authentication.
    - `customData`: Optional metadata (e.g., employee ID, team info).
    - `mechanisms`: Authentication mechanism (e.g., `SCRAM-SHA-256`).
    - `dbRoles`: Object defining DB-specific role mappings.
    - `rolesToRole`: Composite role grouping or hierarchy label.

## Usage

This flavor is suitable for dynamic and automated MongoDB user management within Kubernetes environments. It integrates seamlessly with the MongoDB Auth Operator to:

- Provision secure users with precise access levels.
- Enforce RBAC and custom authentication constraints.
- Assign dynamic roles and collections without manual intervention.
- Easily integrate with DevSecOps pipelines through CRD automation.

Use this when building secure, tenant-aware MongoDB deployments that require declarative access control and minimal human management effort.

## Cloud Providers

- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (Generic)**
