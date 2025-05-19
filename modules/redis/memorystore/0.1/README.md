# Redis Module (Memorystore - GCP)

## Overview

This Redis module provisions a **Google Cloud Memorystore** Redis instance. It delivers a fully managed, secure, and high-performance in-memory key-value store that supports real-time analytics, caching, and session management. The module supports authentication, versioning, persistence options, and customizable sizing for both writer and reader instances.

## Configurability

- **Authenticated**: Enables password protection to secure the Redis instance.  
- **Redis Version**: Specifies the Redis engine version to deploy (e.g., `5.0`).  
- **Persistence Enabled**: Enables or disables data persistence (disabled by default).  
- **Size**:  
  - **Writer**:  
    - **Instance Count**: Number of writer instances.  
    - **Memory**: Allocated memory per writer instance (e.g., `5Gi`).  
  - **Reader**:  
    - **Instance Count**: Number of reader replicas.  
    - **Volume**: Optional storage volume for reader nodes (e.g., `5Gi`).

## Usage

This module allows for automated deployment of Redis via GCP Memorystore with flexible sizing and security options.

Common use cases:

- Accelerating application performance with low-latency caching  
- Managing user session data in distributed systems  
- Supporting real-time analytics and leaderboard workloads  
- Offloading frequent database reads to a high-speed cache
