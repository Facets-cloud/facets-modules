# External PostgreSQL Module

## Overview

The External PostgreSQL module enables integration with externally managed PostgreSQL databases across multiple cloud and container platforms including AWS, GCP, Azure, and Kubernetes. It allows declarative specification of connection details for writer and reader instances without managing the database lifecycle directly.

## Configurability

- **Writer Details**: Configure connection parameters such as host, port, username, and password for the primary PostgreSQL writer instance.  
- **Reader Details**: Configure connection parameters for read-only replicas or secondary PostgreSQL instances to support read scalability.  
- **Multi-cloud and Kubernetes support**: Compatible with PostgreSQL instances hosted on AWS, GCP, Azure, or Kubernetes environments.  
- **Secure credentials**: Password fields support masking and secret referencing for secure handling in UI and automation pipelines.  

## Usage

This module is intended for scenarios where PostgreSQL databases are provisioned and managed externally, and infrastructure-as-code is used only to configure and connect to those instances.

Common use cases:

- Connecting applications to existing managed PostgreSQL databases across multiple cloud providers  
- Defining read/write connection configurations for high availability and read scaling  
- Integrating PostgreSQL hosted outside of the primary infrastructure automation scope  
- Securely managing database credentials in CI/CD and deployment pipelines  
- Supporting hybrid cloud and multi-cloud PostgreSQL deployments with unified configuration
