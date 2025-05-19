# Postgres User Module v0.2

## Overview

This module manages PostgreSQL users and their permissions across AWS, GCP, Azure, and Kubernetes environments. It supports role creation with customizable access levels on specific databases, schemas, and tables. It integrates with Kubernetes clusters and database operators to automate user management.

## Configurability

- **Role Name**  
  - Name of the PostgreSQL role/user to be created.

- **Permissions**  
  - Map of permissions defined per key, each containing:  
    - **Permission**: Access level (`RO`, `RWO`, `ADMIN`).  
    - **Database**: Target database name (alphanumeric, `-` or `_` allowed).  
    - **Schema**: Target schema name (alphanumeric, `-` or `_` allowed).  
    - **Table**: Target table name or wildcard (`*`) to apply permission broadly.

- **Inputs**  
  - Kubernetes cluster details for CRD management.  
  - Database operator responsible for user creation.  
  - Postgres instance details where users are created.

## Usage

Use this module to automate PostgreSQL user role creation and permission assignment in multi-cloud and Kubernetes environments. It ensures fine-grained control over access levels while integrating with Kubernetes operators and database management tools.
