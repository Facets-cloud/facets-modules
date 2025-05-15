# Kafka Kubernetes Module (`flavor: k8s`)

## Overview

This module provisions a **Kafka cluster** along with its **Zookeeper** dependencies in a Kubernetes environment using the `k8s` flavor. It supports configuration of resource requests/limits, instance scaling, version selection, persistence, and optional password authentication.

This module is ideal for users who want to deploy and manage Kafka clusters natively within Kubernetes clusters using declarative infrastructure as code.

## Configurability

The Kafka Kubernetes module requires configuration under the `spec` block, which defines how the Kafka and Zookeeper pods should be deployed and managed.

### ✅ metadata

- `metadata`: *(optional)*  
  Metadata block for resource naming and tracking. Can be left empty.

---

### ✅ spec

#### `authenticated` *(boolean, required)*  
Enables password protection for the Kafka cluster.  
Set to `true` to require authentication, or `false` for unauthenticated access.

#### `kafka_version` *(string, required)*  
The version of Kafka to deploy. Supported values:
- `1.1.1`
- `2.8.0`
- `2.8.1`
- `3.3.2`

#### `persistence_enabled` *(boolean, required)*  
Enable or disable persistent volume claims (PVCs) for Kafka and Zookeeper pods.

#### `size` *(object, required)*  
Specifies sizing and scaling parameters for Kafka and Zookeeper clusters.

---

### Size → `zookeeper` (object, required)

Zookeeper configuration used by the Kafka cluster.

- `cpu` / `cpu_limit`: CPU requests and limits (e.g., `500m`, `1`)
- `memory` / `memory_limit`: Memory requests and limits (e.g., `1Gi`, `800Mi`)
- `volume`: Volume size (e.g., `10Gi`) — shown only when persistence is enabled
- `instance_count`: Number of Zookeeper replicas (e.g., `3`)

---

### Size → `kafka` (object, required)

Kafka broker configuration.

- `cpu` / `cpu_limit`: CPU requests and limits
- `memory` / `memory_limit`: Memory requests and limits
- `volume`: Volume size (e.g., `10Gi`) — shown only when persistence is enabled
- `instance_count`: Number of Kafka broker replicas (e.g., `3`)

---

## Usage

Once this module is applied:

- Kafka and Zookeeper StatefulSets will be deployed into the target Kubernetes cluster.
- If `persistence_enabled` is `true`, PVCs will be created for each replica based on the specified `volume` size.
- Resource requests and limits help ensure scheduling constraints and reliability.
- The Kafka brokers will be exposed via internal Kubernetes networking and can be referenced by dependent workloads.

## Notes

CPU format examples:

Valid: "500m", "1", "32000m"

Memory format examples:

Valid: "512Mi", "2Gi", "64000Mi"

Volume format examples:

Valid: "10Gi", "50Gi"

Resource limit values must be greater than or equal to their corresponding request values.

Volume is only required when persistence_enabled is set to true.



