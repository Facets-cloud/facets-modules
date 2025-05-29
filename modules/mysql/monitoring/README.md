# MySQL Monitoring Module (K8s Flavor)

## Overview

The `mysql_monitoring - k8s` flavor (v0.1) enables comprehensive monitoring and alerting capabilities for MySQL instances running in Kubernetes environments. This module provides predefined alert rules for common MySQL health and performance conditions, helping ensure database reliability and operational visibility.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **MySQL Down Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert (format: duration like '1m5s')
  - **Severity**: Alert severity level (critical, warning)

- **MySQL Too Many Connections Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)
  - **Threshold**: Percentage of maximum connections (0-100%) at which alert triggers

- **MySQL Restarted Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)

## Usage

Use this module to implement comprehensive monitoring and alerting for MySQL deployments in Kubernetes. It is especially useful for:

- Monitoring MySQL availability and detecting service outages or downtime
- Tracking connection usage and preventing connection pool exhaustion
- Detecting unexpected MySQL restarts and service interruptions
- Implementing proactive database health monitoring and incident response
- Supporting production MySQL deployments with automated alerting capabilities
- Enabling operational visibility into MySQL performance and stability
- Supporting database reliability engineering practices with customizable alert thresholds
