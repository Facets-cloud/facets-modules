# Postgres User Module

## Overview

This module manages PostgreSQL users and their permissions across AWS, GCP, Azure, and Kubernetes environments. It allows secure connection configuration and fine-grained permission control on databases, schemas, and tables.

## Configurability

- **Endpoint**  
  - Connection string format: `user:password@host:port`  
- **Permissions**  
  - Define multiple permissions with:  
    - **Permission**: Access level (e.g., `ADMIN`).  
    - **Database**: Target database name.  
    - **Schema**: Schema within the database.  
    - **Table**: Specific table or wildcard (`*`) for all tables.

## Usage

Use this module to automate PostgreSQL user creation and permission assignment, enabling secure and flexible database access management in multi-cloud Kubernetes or cloud-native setups.
