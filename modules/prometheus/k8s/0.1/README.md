# Prometheus Module v0.1

This module deploys a complete Prometheus monitoring stack in Kubernetes clusters using the kube-prometheus-stack Helm chart.

## Overview

The module creates a fully configured Prometheus installation with support for Prometheus server, Alertmanager, Grafana (optional), and the Prometheus operator. It provides comprehensive monitoring capabilities for Kubernetes clusters with configurable resource sizing, data retention, and alert management. The module integrates with Kubernetes nodepool configurations to ensure proper scheduling on designated nodes.

## Environment as Dimension

This module adapts to different cloud environments:

- **AWS**: Integrates with IRSA for service account authentication and EBS volumes for persistence
- **Azure**: Uses Azure disk storage and integrates with Azure Monitor
- **GCP**: Supports Google Kubernetes Engine with persistent disk storage

The module automatically detects the cloud provider and applies appropriate configurations for storage and authentication.

## Nodepool Integration

The module supports integration with Kubernetes node pools through the optional `kubernetes_node_pool_details` input:

- **Tolerations**: Uses only nodepool tolerations when provided (no default tolerations)
- **Node Selector**: Uses nodepool labels as node selectors to target specific node groups
- **Dedicated Scheduling**: When a nodepool is provided, all Prometheus components are scheduled exclusively on those nodes

When no nodepool is provided, Prometheus components will be scheduled based on Kubernetes' default scheduling behavior without any specific tolerations or node selectors.

## Resources Created

- Prometheus operator deployment via Helm chart
- Prometheus server with configurable retention and storage
- Alertmanager for alert routing and notification
- Grafana dashboard (optional)
- Kubernetes ServiceMonitors and PrometheusRules
- Persistent volumes for data storage
- RBAC resources for proper cluster access
- Service accounts with appropriate permissions

## Security Considerations

- Creates minimal RBAC permissions for monitoring access
- Supports service account token authentication
- Configurable alert routing and webhook integrations
- Secure communication between components
- Isolated namespace deployment options

## Inputs

### Required Inputs
- `kubernetes_details`: Kubernetes cluster connection details

### Optional Inputs
- `kubernetes_node_pool_details`: Nodepool configuration for dedicated node scheduling (type: `@outputs/aws_karpenter_nodepool`) 