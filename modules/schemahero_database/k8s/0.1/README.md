# SchemaHero Database - Kubernetes Flavor

## Overview

The `schemahero_database` intent with the `k8s` flavor enables declarative management of databases using SchemaHero within Kubernetes environments. It supports provisioning and configuring databases on various cloud providers including AWS, GCP, Azure, and Kubernetes-managed clusters. This flavor abstracts database connection and lifecycle management into Kubernetes-native resources, allowing teams to automate database setup alongside their infrastructure code.

By defining the connection details declaratively, this approach simplifies database integration with Kubernetes workloads and supports GitOps-driven deployments.

## Configurability

The configuration schema includes the following key properties under the `spec` section:

### connection

- **Type:** `string`  
- **Description:**  
  Specifies the type of database engine, for example, `postgres`, `mysql`, etc. This identifies the database driver to be used.

### uri

- **Type:** `string`  
- **Description:**  
  The full connection URI string used to connect to the target database. It includes credentials, host, port, and database name.  
  Example:  
  `postgresql://username:password@host:port/database`

### disabled

- **Type:** `boolean`  
- **Description:**  
  Optional flag to disable the resource without deleting the configuration, useful for staging or temporarily suspending database provisioning.

## Usage

This flavor is designed for managing database instances declaratively within Kubernetes clusters. It supports common relational databases like PostgreSQL and MySQL across multiple cloud platforms. The resource defines connection parameters enabling SchemaHero to manage database lifecycle and schema changes.

It fits well in GitOps workflows by enabling version-controlled database setup and updates. This allows consistent and automated database provisioning alongside applications and infrastructure in multi-cloud or hybrid deployments.
