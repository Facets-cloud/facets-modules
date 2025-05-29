# MySQL User Module

## Overview

The MySQL User module provisions and manages MySQL user accounts and their associated permissions. It enables secure database access across cloud platforms. This module supports granular access control by allowing permissions at both the database and table levels, tailored to specific workloads.

## Configurability

- **User connection endpoint**: Define the connection string to the MySQL server, including authentication credentials and host address.  
- **Permissions**: Assign one or more permission sets to the user. Permissions can be read-only (`RO`), admin (`ADMIN`), or other custom types.  
- **Database and table-level access**: Grant access to specific databases and tables, or use wildcards (`*`) for broader access.  
- **Disable configuration**: Temporarily disable the MySQL user configuration without deleting it.  
- **Cloud agnostic**: Compatible with AWS, GCP, Azure, and Kubernetes deployments.

## Usage

This module enables declarative configuration of MySQL user accounts and their permissions for secure access control.

Common use cases:

- Creating application-specific MySQL users with read-only access  
- Assigning admin privileges for maintenance or analytics tooling  
- Managing access to multiple databases from a centralized configuration  
- Integrating database credentials into CI/CD pipelines securely  
- Disabling users temporarily during maintenance windows or audits
