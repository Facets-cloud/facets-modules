# MongoDB DocumentDB Flavor Documentation (v0.1)

## Overview

The `mongo - documentdb` flavor (v0.1) provisions a **MongoDB-compatible** instance using **Amazon DocumentDB**, a fully managed, scalable, and highly available document database service designed for JSON workloads. Although not a native MongoDB engine, DocumentDB emulates MongoDB APIs to support most common operations.

This flavor is intended for deployments exclusively on **AWS** infrastructure.

## Configurability

### Specification

- **mongodb_version** (`string`):  
  The targeted MongoDB API version compatibility (e.g., `"5.0"`). Note that this refers to the emulated MongoDB version, not the actual engine version of DocumentDB.

- **size** (`object`):  
  Configuration parameters for the instance size:
  - `instance` (`string`): The instance type for DocumentDB deployment (e.g., `db.r4.large`).
  - `instance_count` (`integer`): Number of nodes in the cluster. For production-grade deployments, use at least 3 for high availability.

## Usage

Use this flavor when deploying **MongoDB-compatible applications** on AWS and seeking:

- A fully managed, serverless alternative to self-managed MongoDB.
- Compatibility with MongoDB drivers and tools (with some limitations).
- Deep integration with AWS IAM, VPC, CloudWatch, and other services.
- Automatic backups, replication, and patching.

> ⚠️ Note: Amazon DocumentDB is **not a drop-in replacement** for all MongoDB features. It supports a subset of MongoDB APIs. Verify compatibility with your application before use.

## Cloud Providers

- **AWS**
