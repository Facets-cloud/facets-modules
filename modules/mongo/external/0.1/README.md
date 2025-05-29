# MongoDB Module (External Flavor)

## Overview

The `mongo - external` flavor (v0.1) enables the integration with existing external MongoDB instances across multiple cloud and Kubernetes environments. This module provides a way to connect to and manage external MongoDB databases that are hosted outside of your current infrastructure setup.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Endpoint**: MongoDB endpoint URL used to connect to the external MongoDB instance (required)
- **Username**: MongoDB username for authentication with the external instance
- **Password**: MongoDB password for authentication with the external instance  
- **Connection String**: Complete MongoDB connection string with protocol for connecting to the external instance (required)

## Usage

Use this module to integrate with external MongoDB databases that are managed outside your current infrastructure. It is especially useful for:

- Connecting to existing MongoDB instances hosted on external cloud providers
- Integrating with legacy MongoDB deployments during migration phases
- Accessing shared MongoDB services across different environments or teams
- Supporting hybrid cloud architectures with external database dependencies
- Enabling applications to connect to MongoDB instances managed by third-party providers
- Facilitating database connections in multi-tenant or multi-environment setups
