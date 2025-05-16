# Loki Recording Rules – Kubernetes Flavor (v0.1)

## Overview

The `loki_recording_rules - k8s` flavor (v0.1) enables the creation and management of Loki recording rules within Kubernetes environments. These rules help in aggregating and summarizing log data for better observability and monitoring.

Supported platforms:
- AWS  
- GCP  
- Azure  
- Kubernetes

## Configurability

### Spec

#### `rules` (object)

Defines the recording rules for Loki. Each rule can be customized with:

- `expr` (`string`)  
  The expression used to aggregate log data.
  
- `disabled` (`boolean`)  
  Enables/disables the rule.
  
- `labels` (`object`)  
  Custom labels to be attached to the rule.

---

### Supported Rules

#### `flog:requests:rate1m`

- **Description**: Aggregates the rate of requests for the `flog` application over 1 minute.
- **Customizable**: `expr`, `disabled`, `labels`

---

#### `flog:requests:rate5m`

- **Description**: Aggregates the rate of requests for the `flog` application over 5 minutes.
- **Customizable**: `expr`, `disabled`, `labels`

---

## Usage

Use this module to define and manage Loki recording rules in Kubernetes environments. It is especially useful for:

- Aggregating log data
- Summarizing log metrics
- Enhancing observability and monitoring
