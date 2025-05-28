# Log Collector Module (Loki Azure Blob Flavor)

## Overview

The `log_collector - loki_azure_blob` flavor (v0.2) enables the deployment and management of log collection infrastructure using Loki with Azure Blob Storage as the storage backend. This module provides a cloud-native logging solution specifically optimized for Azure environments, leveraging Azure Blob Storage for scalable and cost-effective log storage.

Supported clouds:
- Azure
- Kubernetes

## Configurability

- **Advanced Configuration**: Azure Blob Storage-specific Loki configuration for seamless integration with Azure storage services

## Usage

Use this module to implement centralized logging using Loki with Azure Blob Storage backend. It is especially useful for:

- Collecting and aggregating logs from Azure-hosted applications and services
- Leveraging Azure Blob Storage for cost-effective, scalable log storage
- Implementing log retention policies with Azure storage lifecycle management
- Supporting observability and monitoring workflows in Azure and Kubernetes environments
- Integrating with existing Azure logging and monitoring infrastructure
- Providing durable and highly available log storage using Azure Blob Storage
