# Log Collector Module (K8s Flavor)

## Overview

The `log_collector - k8s` flavor (v0.1) enables the deployment and management of log collection infrastructure using Loki and Promtail in Kubernetes environments. This module provides a comprehensive logging solution that collects, processes, stores, and queries logs from various sources within your Kubernetes clusters.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Retention Days**: Number of days to retain logs before deletion (configurable retention period)
- **Storage Size**: Amount of storage allocated for log data (e.g., 5Gi)
- **Advanced Configuration**: Comprehensive Loki stack configuration including:
  - **Loki**: Core log aggregation system with structured configuration for ruler, server, ingester, schema, compactor, querier, and limits
  - **MinIO**: Object storage backend for log data persistence
  - **Promtail**: Log shipping agent with Kubernetes log scraping capabilities
  - **Loki Canary**: Health monitoring and testing component for the Loki deployment

## Usage

Use this module to implement centralized logging for your Kubernetes infrastructure. It is especially useful for:

- Collecting and aggregating logs from all pods and nodes in Kubernetes clusters
- Providing scalable log storage and retention management
- Enabling efficient log querying and analysis across distributed applications
- Implementing alerting rules based on log patterns and metrics
- Supporting observability and debugging workflows in cloud-native environments
- Maintaining compliance with log retention policies and audit requirements
