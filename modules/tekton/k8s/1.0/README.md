# Tekton Pipeline

Deploy Tekton Pipelines on Kubernetes using the official Helm chart from the Continuous Delivery Foundation.

## Overview

This module installs Tekton Pipelines, a Kubernetes-native framework for creating continuous integration and continuous deployment (CI/CD) systems. Tekton provides building blocks to standardize and automate deployments across multiple environments and cloud providers.

## Environment as Dimension

This module is environment-aware through the unique naming and tagging of resources. The Tekton installation will be uniquely named per environment using `var.instance_name` and tagged with environment-specific cloud tags via `var.environment.cloud_tags`.

## Resources Created

- **Helm Release**: Deploys the tekton-pipeline chart from the CDF repository
- **Kubernetes Namespace**: Creates the `tekton-pipelines` namespace if it doesn't exist
- **Tekton Pipeline Components**: All core Tekton Pipeline resources including controllers and webhooks

## Security Considerations

Tekton Pipelines requires cluster-level permissions to manage Kubernetes resources during pipeline execution. The installation includes appropriate RBAC configurations for secure operation within the Kubernetes cluster.

## Requirements

- Kubernetes cluster with sufficient resources for Tekton components
- Helm provider (version ~> 2.8.0)
- Appropriate cluster permissions for creating namespaces and cluster-scoped resources