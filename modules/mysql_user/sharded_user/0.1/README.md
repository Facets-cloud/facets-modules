# MySQL Sharded User Module

## Overview

The MySQL Sharded User module provisions and manages MySQL user accounts across sharded MySQL instances. Designed for distributed database environments, this module allows credentials and permissions to be applied to multiple endpoints simultaneously. It supports secure, cloud-agnostic deployment via Kubernetes, making it ideal for scalable, multi-region MySQL setups.

## Configurability

- **Multi-endpoint support**: Configure credentials across multiple MySQL endpoints using a single resource definition.  
- **Kubernetes-native**: Integrates with Kubernetes to manage users declaratively via CRDs.  
- **Fine-grained permissions**: Control access at database and table levels with roles like `RO`, `ADMIN`, and more.  
- **Wildcard targeting**: Use `*` to grant permissions across all databases or tables.  
- **Multi-cloud readiness**: Operates seamlessly across AWS, GCP, Azure, and Kubernetes-based clusters.  
- **Schema compliance**: Adheres to the defined MySQL User schema for validation and standardization.

## Usage

This module enables consistent MySQL user provisioning across sharded database environments using declarative configuration.

Common use cases:

- Managing access across horizontally sharded MySQL setups  
- Defining unified user permissions over multiple MySQL endpoints  
- Simplifying user management in distributed, high-availability deployments  
- Enforcing access policies programmatically across shards  
- Enabling database automation for multi-region and large-scale workloads
