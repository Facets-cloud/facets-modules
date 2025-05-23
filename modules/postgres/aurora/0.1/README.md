# Aurora PostgreSQL Module (v0.1)

## Overview

The Aurora PostgreSQL v0.1 module provisions and manages PostgreSQL-compatible clusters on **Amazon Aurora** within AWS. It supports configurable PostgreSQL versions, flexible instance sizing for writer and reader nodes, and enables creation of additional databases and schemas. The module also controls whether changes apply immediately or during maintenance windows, catering to both development and production workflows.

## Configurability

- **PostgreSQL Versioning**: Choose from supported versions `12.11`, `13.3`, `14.0`, `15.2`, and `16.1`.
- **Instance Sizing**:
  - **Writer**: Configure instance type (e.g., `db.t3.medium`, `db.m5.large`, etc.) and number of writer nodes.
  - **Reader**: Configure instance type and number of read replicas (optional, can be zero).
- **Additional Databases**: Provide a comma-separated list of extra database names to create alongside the default.
- **Database Schemas**: Define a map of additional schemas linked to specific databases for fine-grained schema management.
- **Apply Behavior**: Optionally apply configuration changes immediately or defer to the next maintenance window.

## Usage

Specify the `postgres_version`, writer and reader instance types and counts, plus any additional databases or schemas in the `spec`. Choose whether to apply changes immediately or delay until the maintenance window.
