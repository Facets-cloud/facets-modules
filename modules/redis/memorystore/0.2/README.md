# Redis Module (Memorystore)

## Overview

This Redis module provisions a **Google Cloud Memorystore for Redis** instance. It offers a fully managed, in-memory key-value store with sub-millisecond latency, designed for caching, session storage, real-time analytics, and state management. The module supports secure access via authentication, Redis version selection, basic persistence control, and fine-grained memory sizing for both reader and writer roles.

## Configurability

- **Authenticated**: Enables password protection for securing Redis access.  
- **Persistence Enabled**: Controls whether data is retained across restarts.  
- **Redis Version**: Select the Redis version to deploy (`3.2`, `4.0`, `5.0`, `6.x`, `7.0`).  
- **Size**:
  - **Writer**:  
    - **Memory**: Memory size allocated to the writer instance (e.g., `5Gi`).
  - **Reader** *(optional)*:  
    - **Memory**: Memory size for reader instances.  
    - **Instance Count**: Number of reader replicas (0–5).

## Usage

This module automates the deployment of Redis using **Google Cloud Memorystore**, offering scalability, availability, and security with declarative configuration.

Common use cases:

- Caching frequently accessed database queries for improved performance  
- Managing session or user state in stateless services  
- Real-time data processing and leaderboard systems  
- Providing a secure, highly available Redis backend with configurable replication
