# Cassandra for Kubernetes Module

## Overview

The Cassandra module provisions and manages Apache Cassandra clusters on Kubernetes. It enables declarative configuration of distributed Cassandra deployments with customizable versioning, compute/memory sizing, storage volumes, and replication settings. Designed for cloud-native environments, it supports scalable, fault-tolerant, and high-throughput NoSQL workloads across AWS, GCP, Azure, and generic Kubernetes platforms.

## Configurability

- **Cassandra versioning**: Choose from supported versions (`5.0.2`, `4.1.7`, `4.0.15`) to ensure compatibility with your application stack.  
- **Resource sizing**: Define CPU and memory requests with optional limits for granular control of compute resources.  
- **Volume configuration**: Set persistent volume size (e.g., `5Gi`) per node for durable data storage.  
- **Instance scaling**: Specify the number of Cassandra nodes (1 to 100) for horizontal scaling.  
- **Resource validation**: Built-in comparisons between requests and limits enforce best practices for Kubernetes deployments.  
- **Namespace targeting**: Deploy Cassandra in a specific Kubernetes namespace to isolate workloads.

## Usage

This module enables platform teams to provision production-ready Cassandra clusters in Kubernetes with strong guarantees around configuration validation and resource governance.

Common use cases:

- Deploying high-availability NoSQL databases in cloud-native microservices architectures  
- Scaling distributed Cassandra clusters for read/write-intensive applications  
- Automating infrastructure provisioning using GitOps and CI/CD pipelines  
- Managing stateful storage and data persistence in Kubernetes environments  
- Creating isolated environments for dev/staging/production with namespace-based deployments
