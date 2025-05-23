# Kafka Kubernetes Module (`flavor: k8s`, `version: 0.3`)

## Overview

This module provisions a **Kafka cluster** in Kubernetes using **KRaft mode (Kafka Raft metadata mode)**, removing the need for Zookeeper and allowing Kafka controllers and brokers to run natively. It supports detailed configuration for Kafka controllers and brokers, including resource limits, persistence, and high availability, along with optional authentication support.

This module enables you to run a production-grade Kafka cluster using modern KRaft architecture directly within Kubernetes.

## Configurability

The configuration is divided into two main sections: **controller** and **broker**, along with top-level Kafka cluster settings.

---

**`metadata`**

- `namespace`:
  The namespace in which Kafka should be deployed.

---

**`spec`**

- **`authenticated`**:  
Enable or disable password-based authentication for the Kafka cluster.

- **`kafka_version`**: 
Version of Kafka to deploy. Only supported value: `3.8.0`

- **`mode`**:  
Defines the Kafka deployment mode. Only supported value: `kraft`

---

**controller**

Configuration for the **Kafka controller** nodes.

- `controller_only`: *(boolean, required)*  
  Whether to run dedicated controller-only nodes.

- `persistence_enabled`: *(boolean, required)*  
  Whether to enable persistent storage for the controllers.

- `size`: *(object, required)*  
  Resource sizing for Kafka controller nodes.

  **Fields inside `controller.size`:**
  - `cpu`, `cpu_limit`: CPU requests and limits.
  - `memory`, `memory_limit`: Memory requests and limits.
  - `volume`: Persistent volume size (only required if `persistence_enabled` is true).
  - `instance_count`: Number of controller replicas to deploy.

---

**`broker`**

Configuration for the **Kafka broker** nodes.

- `persistence_enabled`: *(boolean, required)*  
  Whether to enable persistent storage for the brokers.

- `size`: *(object, required)*  
  Resource sizing for Kafka broker nodes.

  **Fields inside `broker.size`:**
  - `cpu`, `cpu_limit`: CPU requests and limits.
  - `memory`, `memory_limit`: Memory requests and limits.
  - `volume`: Persistent volume size (only required if `persistence_enabled` is true).
  - `instance_count`: Number of broker replicas to deploy.

---

## Usage

Once configured:

- Kafka controllers and brokers will be deployed as StatefulSets.
- If `persistence_enabled` is true, PersistentVolumeClaims (PVCs) will be created.
- You can choose between dedicated controller-only mode or colocated controllers and brokers.
- All settings are fully declarative and integrated into your environment’s lifecycle.

## Notes
The module only supports Kafka version 3.8.0 and KRaft mode in this release.

If persistence_enabled is true, the volume field is required to specify disk storage for each pod.

The resource fields like cpu, memory, and their limits must be expressed in valid Kubernetes format (e.g., 500m, 2Gi).

instance_count should reflect the desired number of Kafka brokers and controller pods.

If controller_only is set to false, controllers may run along with brokers, though dedicated controllers (true) are generally recommended for production clusters.

