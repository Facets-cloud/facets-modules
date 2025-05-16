# Elasticsearch Monitoring - Kubernetes Flavor (v0.1)

## Overview

This module adds monitoring capabilities to Elasticsearch deployments on Kubernetes, supporting major cloud platforms including AWS, Kubernetes native, Azure, and GCP. It enables configurable alerts for key Elasticsearch health and performance indicators, allowing timely detection and response to issues such as cluster status changes, disk space shortages, and heap memory pressure.

## Configurability

The monitoring configuration supports multiple alert types with fine-grained controls:

- **Elasticsearch Down:** Alert triggered when the Elasticsearch service is unreachable.
- **Elasticsearch Cluster Yellow:** Alert for cluster status degraded to yellow.
- **Elasticsearch Cluster Red:** Alert for critical cluster status (red).
- **Elasticsearch Disk Out Of Space:** Alert when available disk space falls below a specified threshold percentage.
- **Elasticsearch Heap Too High:** Alert when JVM heap usage exceeds a specified percentage threshold.
- **Elasticsearch Cluster Has Unassigned Shards:** Alert for cluster shards that remain unassigned.

Each alert supports these configurable properties:

- **Disabled:** Enable or disable the alert.
- **Interval:** The duration that the alert condition must persist before triggering, specified with a flexible time pattern (e.g., `1m5s`, `72h`, `500ms`).
- **Severity:** Categorizes the urgency or impact level of the alert (e.g., warning, critical).
- **Threshold:** Numeric thresholds for applicable alerts, such as disk space and heap usage percentage (range 0-100).

Validation patterns and UI hints ensure correct and consistent user input.

## Usage

To enable Elasticsearch monitoring, configure the alerts section in the specification by specifying desired alert types and their properties. Alerts can be individually enabled or disabled, with custom intervals and severity levels tailored to operational needs. Threshold values must be set for applicable alerts to define triggering criteria. This module integrates directly with existing Elasticsearch outputs to seamlessly extend monitoring capabilities.

Example usage includes defining alert thresholds for disk space and heap memory, setting critical severities for cluster down or red status, and configuring intervals that control alert sensitivity to transient conditions.
