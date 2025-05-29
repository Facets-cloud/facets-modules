# Redis Module (Azure Cache)

## Overview

This Redis module provisions a managed Redis instance on Microsoft Azure using the Azure Cache for Redis service. It enables in-memory data storage that is fast, scalable, and suitable for caching, real-time analytics, and session storage. The module supports authentication, persistence, version selection, and reader instance configuration.

## Configurability

- **Authenticated**: Enables password protection to secure the Redis instance.  
- **Persistence Enabled**: Ensures data durability across restarts by enabling persistence.  
- **Redis Version**: Specifies the Redis version to deploy (supported versions: `4.0`, `6.0`).  
- **Size**:  
  - **Reader**:  
    - **Instance Count**: Number of reader replicas to create (between 0 and 3).

## Usage

This module helps automate provisioning of Azure Cache for Redis with configurable options for security, performance, and scalability.

Common use cases:

- Deploying a secure and scalable in-memory cache  
- Accelerating application performance through low-latency data access  
- Persisting session or state data in distributed systems  
- Offloading frequent queries with a high-speed cache layer
