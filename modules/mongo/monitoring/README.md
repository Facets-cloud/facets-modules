# MongoDB Monitoring Module (K8s Flavor)

## Overview

The `mongo_monitoring - k8s` flavor (v0.1) enables comprehensive monitoring and alerting capabilities for MongoDB instances running in Kubernetes environments. This module provides predefined alert rules for common MongoDB health and performance conditions, helping ensure database reliability and performance.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **MongoDB Down Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert (format: duration like '1m5s')
  - **Severity**: Alert severity level (critical, warning)

- **MongoDB Too Many Connections Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)
  - **Threshold**: Percentage of maximum connections (0-100%) at which alert triggers

- **MongoDB Virtual Memory Usage Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)
  - **Threshold**: Maximum memory percentage (0-100%) for each MongoDB instance

- **MongoDB Replication Lag Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)
  - **Threshold**: Replication lag threshold in seconds (minimum 0.1)

- **MongoDB Replica Member Unhealthy Alert**:
  - **Disabled**: Toggle to enable/disable the alert
  - **Interval**: Time duration before triggering the alert
  - **Severity**: Alert severity level (critical, warning)

## Usage

Use this module to implement comprehensive monitoring and alerting for MongoDB deployments in Kubernetes. It is especially useful for:

- Monitoring MongoDB availability and detecting service outages
- Tracking connection usage and preventing connection pool exhaustion
- Monitoring memory consumption and resource utilization
- Detecting replication lag issues in MongoDB replica sets
- Identifying unhealthy replica set members and cluster issues
- Implementing proactive database health monitoring and incident response
- Supporting production MongoDB deployments with automated alerting capabilities
