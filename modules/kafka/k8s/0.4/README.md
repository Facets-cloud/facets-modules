# Kafka Kubernetes Module (`flavor: k8s`, `version: 0.4`)

## Overview

This module provisions a **Kafka cluster** in Kubernetes using **KRaft mode (Kafka Raft metadata mode)**, removing the need for Zookeeper and allowing Kafka controllers and brokers to run natively. It supports detailed configuration for Kafka controllers and brokers, including resource limits, persistence, and high availability, along with optional authentication support.

**Key change from v0.3:** The kafka-lag-exporter (JVM-based, amd64 only) has been replaced with **klag-exporter** (Rust-based), which supports both **AMD64 and ARM64** architectures. The klag-exporter is pulled from the OCI registry at `ghcr.io/softwaremill/helm/klag-exporter`.

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

## Advanced Configuration (klag-exporter)

The klag-exporter can be customized via the `advanced.k8s.kafka_lag_exporter` block. Available options:

- `repository`: OCI repository override (default: `oci://ghcr.io/softwaremill/helm`)
- `chart`: Chart name override (default: `klag-exporter`)
- `chart_version`: Chart version override (default: `0.1.23`)
- `poll_interval`: How often to poll Kafka for lag metrics (default: `10s`)
- `granularity`: Metric granularity - `topic` or `partition` (default: `topic`)
- `timestamp_sampling_enabled`: Enable time-lag estimation (default: `true`)
- `timestamp_sampling_mode`: Time-lag mode - `rate` or `message` (default: `rate`)
- `config`: Additional config map merged into the klag-exporter config section
- `values`: Additional values merged into the helm release values

---

## Usage

Once configured:

- Kafka controllers and brokers will be deployed as StatefulSets.
- If `persistence_enabled` is true, PersistentVolumeClaims (PVCs) will be created.
- You can choose between dedicated controller-only mode or colocated controllers and brokers.
- klag-exporter will be deployed alongside Kafka for consumer lag monitoring, with Prometheus ServiceMonitor enabled by default.
- All settings are fully declarative and integrated into your environment's lifecycle.

## Notes
The module only supports Kafka version 3.8.0 and KRaft mode in this release.

If persistence_enabled is true, the volume field is required to specify disk storage for each pod.

The resource fields like cpu, memory, and their limits must be expressed in valid Kubernetes format (e.g., 500m, 2Gi).

instance_count should reflect the desired number of Kafka brokers and controller pods.

If controller_only is set to false, controllers may run along with brokers, though dedicated controllers (true) are generally recommended for production clusters.

The klag-exporter uses SASL_PLAINTEXT with SCRAM-SHA-256 for authenticated clusters (matching the Kafka broker SASL config). For unauthenticated clusters, it connects with PLAINTEXT.
