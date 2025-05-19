# SchemaHero Database Module

## Overview

The SchemaHero Database module provides a way to manage database schemas declaratively within Kubernetes. It connects to relational databases like PostgreSQL or MySQL and applies schema changes automatically based on version-controlled definitions. This approach ensures consistency, simplifies collaboration, and reduces the risk of manual errors across development and production environments.

## Configurability

- **Connection type**: Defines the database engine (e.g., `postgres`, `mysql`).  
- **Connection URI**: Full connection string used to connect to the database.  
- **Flavor**: Specifies the deployment target, such as 'k8s'.  
- **Disabled**: Allows disabling the module without deleting its configuration.  
- **Immediate deploy**: Controls whether schema changes are applied immediately or deferred.

## Usage

This module supports automated, version-controlled schema management using SchemaHero in Kubernetes environments.

Common use cases:

- Managing and versioning database schemas as code  
- Automating schema migrations in CI/CD workflows  
- Maintaining schema consistency across environments  
- Auditing and tracking schema changes over time  
- Standardizing database workflows across different cloud setups
