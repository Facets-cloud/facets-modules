# Loki Alerting Rules – Kubernetes Flavor (v0.1)

## Overview

The `loki_alerting_rules - k8s` flavor (v0.1) enables the creation and management of Loki alerting rules within Kubernetes environments. These rules help in detecting and alerting on specific log patterns and conditions for better observability and monitoring.

Supported platforms:
- AWS  
- GCP  
- Azure  
- Kubernetes

## Configurability

### Spec

#### `rules` (object)

Defines the alerting rules for Loki. Each rule can be customized with:

- `expr` (`string`)  
  The expression used to detect log patterns.
  
- `message` (`string`)  
  The message to be sent when the alert is triggered.
  
- `summary` (`string`)  
  A brief summary of the alert.
  
- `for` (`string`)  
  The duration for which the condition must be true before the alert is triggered.
  
- `labels` (`object`)  
  Custom labels to be attached to the alert.
  
- `disabled` (`boolean`)  
  Enables/disables the alert.
  
- `resource_name` (`string`)  
  The name of the resource associated with the alert.
  
- `resource_type` (`string`)  
  The type of resource associated with the alert.

---

### Supported Rules

#### `HighPercentageError`

- **Description**: Alerts when the percentage of errors in the `foo` application in the production environment exceeds 5% over 5 minutes.
- **Customizable**: `expr`, `message`, `summary`, `for`, `labels`, `disabled`, `resource_name`, `resource_type`

---

#### `TestAlert`

- **Description**: Alerts when the rate of `info` level logs for the `loki` application exceeds 0 per minute.
- **Customizable**: `expr`, `message`, `summary`, `for`, `labels`, `disabled`, `resource_name`, `resource_type`

---

## Usage

Use this module to define and manage Loki alerting rules in Kubernetes environments. It is especially useful for:

- Detecting log patterns
- Triggering alerts based on log conditions
- Enhancing observability and monitoring
