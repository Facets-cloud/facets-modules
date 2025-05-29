# Kubernetes Secret Module (K8s Flavor)

## Overview

The `kubernetes_secret - k8s` flavor (v0.3) enables the creation and management of Kubernetes secrets across multiple cloud environments. This module provides a standardized way to define and deploy sensitive data such as passwords, OAuth tokens, SSH keys, and other confidential information within Kubernetes clusters.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Data**: Data objects containing key-value pairs for Kubernetes secrets. Each data object includes:
  - **Key**: The name of the Kubernetes secret data key (must follow pattern: alphanumeric characters, underscores, dots, and hyphens only)
  - **Value**: The value of the Kubernetes secret data object (supports multi-line text input)

## Usage

Use this module to create and manage Kubernetes secrets for storing sensitive information securely within your Kubernetes clusters. It is especially useful for:

- Storing and managing sensitive configuration data like API keys, passwords, and certificates
- Providing secure access to confidential information for applications running in Kubernetes
- Maintaining consistent secret management practices across multi-cloud Kubernetes deployments
- Enabling secure configuration injection into pods and containers
