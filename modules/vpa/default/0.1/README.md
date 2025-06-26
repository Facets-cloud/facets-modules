# VPA (Vertical Pod Autoscaler) Module

![Status](https://img.shields.io/badge/status-stable-green)

## Overview

This module deploys the Vertical Pod Autoscaler (VPA) to automatically analyze and recommend optimal CPU and memory resource requests for Kubernetes workloads. VPA helps right-size containers by learning from their actual resource usage patterns over time.

The module provides automated resource recommendations through the VPA recommender component while allowing selective enablement of the updater and admission controller components based on operational requirements.

## Environment as Dimension

The module is environment-aware and adapts its configuration based on:
- **Namespace**: VPA can be deployed to environment-specific namespaces (default: `vpa-system`)
- **Node Selection**: Automatically configures node selectors and tolerations based on available node pools
- **Resource Sizing**: Recommender resource requirements can be adjusted per environment
- **Prometheus Integration**: Connects to environment-specific Prometheus instances for historical metrics

## Resources Created

- **Kubernetes Namespace**: Optional namespace creation for VPA components
- **Helm Release**: VPA deployment using the official Fairwinds Helm chart
- **VPA Recommender**: Core component that analyzes workload resource usage and provides recommendations
- **VPA Updater**: Optional component that can automatically apply resource recommendations (disabled by default)
- **VPA Admission Controller**: Optional component that applies recommendations to new pods (disabled by default)

## Security Considerations

- The VPA recommender requires read access to Kubernetes metrics and pod information
- When enabled, the VPA updater requires permissions to modify pod resource specifications
- The admission controller, if enabled, requires webhook permissions to intercept pod creation requests
- All components are deployed with appropriate RBAC permissions scoped to their functional requirements
- The module supports deployment on dedicated node pools with appropriate taints and tolerations