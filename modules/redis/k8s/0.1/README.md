# Redis Module (Kubernetes)

## Overview

This Redis module provisions a Redis deployment **inside a Kubernetes cluster** using Helm. It offers a flexible, in-cluster in-memory data store with customizable compute resources, storage persistence, and optional read replicas. Ideal for scenarios requiring fast access, low-latency caching, or distributed state sharing within Kubernetes applications.

## Configurability

- **Authenticated**: Enables password protection to secure access to the Redis service.  
- **Persistence Enabled**: Controls whether data is persisted using persistent volumes across pod restarts (enabled by default).  
- **Redis Version**: Specifies the Redis version to deploy (e.g., `7.0.11`).  
- **Size**:  
  - **Writer**:  
    - **CPU & Memory**: Define resource requests and limits for the primary Redis node.  
    - **Volume Size**: Persistent storage volume size for the writer pod (e.g., `5Gi`, `10Gi`).  
  - **Reader (Optional)**:  
    - **CPU & Memory**: Resource configuration for Redis read replicas.  
    - **Volume Size**: Storage size for persistent volume claims used by readers.  

## Usage

This module automates Redis deployment inside Kubernetes via Helm charts, enabling secure, scalable, and persistent in-memory data storage for containerized workloads.

Common use cases:

- Providing shared in-memory storage for Kubernetes microservices  
- Caching frequent API or DB responses within a cluster  
- Supporting scalable read-heavy operations with replica pods  
- Managing transient or session data in a high-availability environment  
