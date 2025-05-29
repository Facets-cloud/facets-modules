# MySQL User Module

## Overview

The MySQL User module provisions and manages MySQL user accounts and permissions via Kubernetes Custom Resources, using Crossplane as the controller. Designed for cloud-agnostic deployments, it integrates with Kubernetes clusters across AWS, GCP, Azure, and other environments. This module allows you to declaratively define user access policies at the database and table levels using familiar infrastructure-as-code patterns.

## Configurability

- **Kubernetes integration**: Deploys CRDs in a Kubernetes cluster to manage MySQL users declaratively.  
- **Crossplane support**: Uses Crossplane to automate the creation and reconciliation of MySQL user accounts.  
- **MySQL endpoint configuration**: Links to a MySQL instance where the user and permissions will be applied.  
- **Permissions**: Fine-grained control over user roles such as `RO`, `RWO`, `ADMIN`, `RWC`, `RWD`, and `RWCT`.  
- **Database and table-level targeting**: Grant access to specific databases and tables, or use wildcards (`*`) for broader scope.  
- **Lifecycle scoped to ENVIRONMENT**: User resource lifecycle is tied to the parent environment, allowing for better lifecycle management.  
- **Input-type: instance**: Accepts external Kubernetes, Crossplane, and MySQL resources as inputs for flexible composition.

## Usage

This module enables cloud-native management of MySQL user accounts and their permissions through Kubernetes and Crossplane.

Common use cases:

- Defining MySQL user permissions in code as part of an environment's lifecycle  
- Integrating database access provisioning into GitOps workflows  
- Enforcing least-privilege access across applications and services  
- Managing users across multi-cloud or hybrid Kubernetes environments  
- Enabling DevOps teams to manage DB access via infrastructure definitions
