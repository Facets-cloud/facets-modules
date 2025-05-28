# Log Collector Module (Loki Azure Blob Flavor)

## Overview

The `log_collector - loki_azure_blob` flavor (v0.1) enables the deployment and management of log collection infrastructure using Loki with Azure Blob Storage as the storage backend. This module provides a cloud-native logging solution specifically optimized for Azure environments, leveraging Azure Blob Storage for scalable and cost-effective log storage.

Supported clouds:
- Azure

## Configurability

- **Retention Days**: Number of days to retain logs before deletion (configurable retention period)
- **Storage Size**: Storage size configuration for log data
- **Advanced Configuration**: Azure Blob Storage-specific Loki configuration including:
  - **Container Name**: Reference to the Azure Storage Container where logs will be stored
  - **Primary Access Key**: Reference to the access key of the Azure Storage Container
  - **Storage Account Name**: Reference to the name of the Azure Storage Account

## Usage

Use this module to implement centralized logging using Loki with Azure Blob Storage backend. It is especially useful for:

- Collecting and aggregating logs from Azure-hosted applications and services
- Leveraging Azure Blob Storage for cost-effective, scalable log storage
- Implementing log retention policies with Azure storage lifecycle management
- Supporting observability and monitoring workflows in Azure environments
- Integrating with existing Azure logging and monitoring infrastructure
- Providing durable and highly available log storage using Azure Blob Storage
