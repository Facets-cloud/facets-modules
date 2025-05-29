# Postgres User Module v0.3

## Overview

This module manages PostgreSQL users and roles with detailed role specifications and fine-grained permissions across AWS, GCP, Azure, and Kubernetes. It automates user creation, role configuration, password management, and execution of custom grant statements. Integration with Kubernetes clusters and database operators allows seamless management in multi-cloud and Kubernetes environments.

## Configurability

- **Postgres User**  
  - **Role Name**: PostgreSQL role/user name (must start with a letter, alphanumeric and dashes allowed).  
  - **Role**:  
    - **Connection Limit**: Max simultaneous connections for the role.  
    - **Privileges**: Boolean flags for role privileges such as `superuser`, `login`, `create_db`, `replication`, `bypass_rls`, etc.  
  - **User Password**: Password for the PostgreSQL user.  
  - **Grant Statements**:  
    - Map keyed by identifier.  
    - Each entry includes target database and a list of SQL grant statements to execute after role creation.  
  - **Connection Details**:  
    - Default database to connect to (default `postgres`).  
    - SSL mode (default `disable`).

- **Inputs**  
  - Kubernetes cluster details for managing CRDs.  
  - Database operator responsible for user and role management.  
  - Postgres instance connection details.

## Usage

Use this module to provision PostgreSQL users with customizable roles and privileges. It supports running custom grant statements per database, allowing precise permission control post-creation. Designed for cloud-native environments integrating Kubernetes operators and database management tooling.
