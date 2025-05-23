# Redis Module (ElastiCache)

## Overview

This Redis module provisions a managed Redis cluster using **AWS ElastiCache**. It enables secure, scalable, and high-performance in-memory caching and data storage with support for password authentication, persistence options, and flexible sizing through AWS-supported instance types.

## Configurability

- **Authenticated**: Enables password protection for accessing the Redis service.  
- **Persistence Enabled**: Determines whether data is retained across restarts.  
- **Redis Version**: Select the Redis version to deploy (e.g., `5.0.6`, `6.x`).  
- **Size**:
  - **Instance Type**: Choose from a wide range of AWS ElastiCache instance types (e.g., `cache.t3.micro`, `cache.r6g.large`, `cache.m5.xlarge`).
  - **Instance Count**: Number of Redis instances to provision (1–10).

## Usage

This module allows automated deployment of Redis via AWS ElastiCache with declarative configuration.

Common use cases:

- Accelerating API and database performance with in-memory caching  
- Handling session and user state in distributed applications  
- Scaling read-heavy workloads with multiple Redis replicas  
- Deploying secure, managed Redis with fine-grained sizing control
