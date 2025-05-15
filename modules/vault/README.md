# Vault (Kubernetes Flavor)

## Overview

This module deploys a HashiCorp Vault cluster on Kubernetes using Facets automation. It supports both standalone and high-availability modes. Vault is managed via Helm charts and works across AWS, Azure, GCP, and Kubernetes. The module automates Vault initialization, unsealing, and root token storage.

## Configurability

Key settings include Vault version, instance count, CPU and memory requests/limits, and persistent volume size. Advanced Helm values and timeouts can also be customized. Lifecycle automation handles pod readiness, Vault initialization, and secure storage of credentials in Kubernetes secrets.

## Usage

Use this module to deploy Vault for secure secret storage, identity-based access, and encryption workflows. It supports standalone and HA modes with Raft. Common scenarios include managing app secrets, dynamic cloud resource credentials, and centralized encryption management. Vault is accessible internally on port 8200, with root tokens stored securely.
