# SchemaHero Table - Kubernetes Flavor

## Overview

The `schemahero_table` intent with the `k8s` flavor provides a declarative way to define and manage database tables using SchemaHero on Kubernetes. This flavor supports provisioning tables across multiple cloud databases including AWS, GCP, Azure, and Kubernetes-managed databases. It enables automated schema management by describing table structures, columns, and keys in a Kubernetes-native format, simplifying database operations within cloud-native environments.

This approach abstracts direct database interactions, allowing infrastructure as code for database schemas that integrates smoothly with Kubernetes workflows and GitOps pipelines.

## Configurability

The schema exposes the following properties under the `spec` section:

### database

- **Type:** `string`
- **Description:**  
  Specifies the target database name where the table will be created.

### connection

- **Type:** `string`
- **Description:**  
  Defines the type of database connection or engine, such as `mysql`, `postgres`, or others supported by SchemaHero.

### primary_key

- **Type:** `array`
- **Description:**  
  Lists one or more columns that constitute the primary key for the table. This ensures uniqueness and indexing on specified columns.

### columns

- **Type:** `object`
- **Description:**  
  Defines the columns in the table. Each entry specifies a column with its name and data type.
- **Properties:**
  - `name`: The column name.
  - `type`: The data type for the column (e.g., `char(4)`, `varchar(100)`).

Columns are enumerated with arbitrary keys (such as `'1'`, `'2'`, etc.) to uniquely identify each column definition.

### disabled

- **Type:** `boolean`
- **Description:**  
  Optionally disables the creation or modification of this table resource without deleting the configuration.

## Usage

This flavor is useful for managing database table schemas declaratively in Kubernetes clusters. It supports common relational database engines, allowing teams to version and automate schema changes. By defining columns and primary keys explicitly, it ensures database consistency and integrity. This flavor integrates well with GitOps workflows, enabling seamless deployment and update of database schemas alongside application code.

Deployments can target multiple cloud providers and database engines, making it flexible for hybrid or multi-cloud architectures.
