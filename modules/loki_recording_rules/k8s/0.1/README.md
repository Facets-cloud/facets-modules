# Loki Recording Rules Module (K8s Flavor)

## Overview

The `loki_recording_rules - k8s` flavor (v0.1) enables the creation and management of recording rules for Loki-based log monitoring in Kubernetes environments. This module provides the ability to define pre-computed metrics from log data, allowing for efficient querying and analysis of frequently accessed log-derived metrics.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Rules**: Collection of recording rules with the following properties for each rule:
  - **Expression (expr)**: LogQL query expression that defines the metric calculation
  - **Disabled**: Flag to enable/disable individual recording rules
  - **Labels**: Custom labels to be attached to the recorded metrics for categorization and filtering

## Usage

Use this module to implement pre-computed metrics from log data for efficient monitoring and analysis. It is especially useful for:

- Creating frequently accessed metrics from log data to improve query performance
- Pre-computing complex log aggregations for dashboards and alerting
- Generating time-series metrics from structured log data (JSON, logfmt, etc.)
- Supporting efficient monitoring dashboards with pre-calculated metrics
- Reducing query load on Loki by storing commonly used metric calculations
- Enabling faster visualization and analysis of log-derived data
- Supporting observability workflows across multi-cloud Kubernetes environments
