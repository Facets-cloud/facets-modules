# Zookeeper Module (Kubernetes Flavor)

## Overview
This module adds support for deploying Zookeeper using the Kubernetes flavor. It enables provisioning and management of Zookeeper instances via Facets infrastructure automation across multiple cloud platforms including AWS, GCP, Azure, and native Kubernetes environments.

It supports customization of Zookeeper version, resource sizing, and replica count, making it suitable for various deployment scenarios like coordination of distributed applications, service discovery, and maintaining configuration information consistently across services.

## Configurability
The following options can be configured using the `spec` section of the input manifest:

- **zookeeper_version**: The version of Zookeeper to be deployed.  
  _Example: `3.8.1`_

- **size**: Defines the resource allocation for the Zookeeper pod:
  - `cpu`: Amount of CPU to allocate (e.g., `500m`)
  - `memory`: Amount of memory to allocate (e.g., `500Mi`)
  - `volume`: Volume size for persistent storage (e.g., `8Gi`)
  - `replica_count`: Number of replicas to maintain for high availability

## Usage
This module provisions a Zookeeper cluster within a Kubernetes environment. It is commonly used for:

- Distributed configuration management
- Synchronization primitives (locks, barriers, queues)
- Service discovery and naming
- Leader election in distributed systems

