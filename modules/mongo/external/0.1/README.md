# MongoDB External Flavor Documentation (v0.1)

## Overview

The `mongo - external` flavor (v0.1) is designed for integrating with an **externally managed MongoDB instance**, rather than provisioning a new cluster. This allows connection to MongoDB databases hosted outside the platform—such as self-managed clusters or third-party hosted MongoDB services.

This flavor is compatible with deployments across **AWS**, **Azure**, **GCP**, and **Kubernetes** environments.

## Configurability

### Specification

- **connection_string** (`string`, required):  
  The full MongoDB URI including protocol (e.g., `mongodb://username:password@host:port/db`).  
  This is the primary connection method.

- **endpoint** (`string`, required):  
  The MongoDB endpoint (hostname or IP address) for monitoring or compatibility use.

- **username** (`string`, optional):  
  Username for authenticating with the MongoDB instance.

- **password** (`string`, optional):  
  Password for authenticating with the MongoDB instance.

> ✅ Use either the individual `username`, `password`, and `endpoint` fields for granular control, or rely entirely on `connection_string`.

## Usage

Use this flavor when:

- Connecting to a **pre-existing MongoDB** instance managed outside the system.
- Integrating with **MongoDB-as-a-Service** solutions like MongoDB Atlas or other cloud vendors.
- Avoiding the overhead of managing infrastructure for MongoDB deployments.

Ensure that:

- The connection string provided has correct network and authentication details.
- The external database is accessible from the deployment environment.

## Cloud Providers

- **AWS**
- **Azure**
- **GCP**
- **Kubernetes**
