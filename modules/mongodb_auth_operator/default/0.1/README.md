# MongoDB Auth Operator Module (Default Flavor)

## Overview

The `mongodb_auth_operator - default` flavor (v0.1) enables the deployment and management of the MongoDB Auth Operator in Kubernetes environments. This operator provides automated user and role management capabilities for MongoDB instances, allowing for declarative configuration of MongoDB authentication and authorization through Kubernetes Custom Resource Definitions (CRDs).

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Input Dependencies**:
  - **Kubernetes Details**: Kubernetes cluster where the MongoDB Auth Operator will be installed

- **Size Configuration**:
  - **CPU Limit**: CPU resource limit for the operator instance (format: number 1-32 or 1m-32000m)
  - **Memory Limit**: Memory resource limit for the operator instance (format: 1Gi-64Gi or 1Mi-64000Mi)

- **Values**: Custom Helm chart values in YAML format for advanced operator configuration

## Usage

Use this module to deploy the MongoDB Auth Operator for automated MongoDB user and role management in Kubernetes. It is especially useful for:

- Enabling declarative MongoDB user management through Kubernetes CRDs
- Automating MongoDB authentication and authorization workflows
- Providing operator-based lifecycle management for MongoDB users and roles
- Supporting GitOps and Infrastructure as Code approaches for database access control
- Integrating MongoDB security management with Kubernetes-native tooling
- Enabling centralized management of MongoDB authentication across multiple database instances
- Supporting compliance and security requirements through automated user provisioning and deprovisioning
