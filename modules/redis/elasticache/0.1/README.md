# Redis Module (ElastiCache)

## Overview

This Redis module provisions an AWS ElastiCache for Redis instance. It offers a fully managed, in-memory data store service that delivers sub-millisecond latency, ideal for caching, real-time analytics, and state management. The module supports authentication, version control, instance sizing, and basic persistence options.

## Configurability

- **Authenticated**: Enables password protection to secure the Redis instance.  
- **Persistence Enabled**: Controls whether data is persisted across restarts (disabled by default).  
- **Redis Version**: Specifies the Redis version to deploy (e.g., `6.x`).  
- **Size**:  
  - **Instance Count**: Number of ElastiCache instances to provision.  
  - **Instance Type**: AWS EC2 instance type used for each Redis node (e.g., `cache.t3.micro`).

## Usage

This module automates the deployment of Redis on AWS using ElastiCache, allowing easy configuration for performance, availability, and security.

Common use cases:

- Accelerating application performance with fast, in-memory caching  
- Storing ephemeral session or token data  
- Offloading repetitive database queries with a cache layer  
- Scaling distributed applications with low-latency key-value storage
