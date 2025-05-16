# MongoDB Monitoring – Kubernetes Flavor (v0.1)

## Overview

The `mongo_monitoring - k8s` flavor (v0.1) enables real-time monitoring and alerting for MongoDB clusters deployed in Kubernetes environments. It integrates seamlessly with the `mongo` module to provide health checks, performance thresholds, and fault detection.

Supported platforms:
- AWS  
- Azure  
- GCP  
- Kubernetes

> ⚠️ This module requires a reference to an existing `@output/mongo` deployment.

## Configurability

### Spec

#### `alerts` (object)

Defines alert rules for key MongoDB operational metrics. Each alert can be customized with:

- `disabled` (`boolean`)  
  Enables/disables the alert.
  
- `interval` (`string`)  
  Duration format to evaluate the alert condition (e.g., `5m`, `2h`, `30s`).  
  Must match: `^(\d+(\.\d+)?(h|m|s|ms|us|µs|ns))+$`

- `severity` (`string`)  
  Priority of the alert:  
  - `critical`
  - `warning`

Additional properties vary per alert type:

---

### Supported Alerts

#### `mongodb_down`

- **Description**: Triggers if MongoDB becomes unreachable.
- **Customizable**: `disabled`, `interval`, `severity`

---

#### `mongodb_too_many_connections`

- **Description**: Alerts when MongoDB nears/exceeds its connection limit.
- **Additional field**:
  - `threshold` (`integer`, 0–100): Connection usage percentage.

---

#### `mongodb_virtual_memory_usage`

- **Description**: Triggers if memory usage exceeds acceptable limits.
- **Additional field**:
  - `threshold` (`integer`, 0–100): Memory usage percentage.

---

#### `mongodb_replication_lag`

- **Description**: Raises alert if replication lag grows beyond tolerance.
- **Additional field**:
  - `threshold` (`float`, minimum: 0.1): Lag duration in seconds.

---

#### `mongodb_replica_member_unhealthy`

- **Description**: Detects if a replica set member becomes unhealthy.
- **Customizable**: `disabled`, `interval`, `severity`

---

## Usage

Use this module to ensure observability and early fault detection in MongoDB deployments on Kubernetes. It is especially useful for:

- Production-grade replica sets
- High availability systems
- Environments with strict SLAs
