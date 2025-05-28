# Log Collector Module (Loki AWS S3 Flavor)

## Overview

The `log_collector - loki_aws_s3` flavor (v0.1) enables the deployment and management of log collection infrastructure using Loki with AWS S3 as the storage backend. This module provides a cloud-native logging solution specifically optimized for AWS environments, leveraging S3 for scalable and cost-effective log storage.

Supported clouds:
- AWS

## Configurability

- **Retention Days**: Number of days to retain logs before deletion (configurable retention period)
- **Storage Size**: Storage size configuration for log data
- **Advanced Configuration**: AWS S3-specific Loki configuration including:
  - **Bucket Name**: Reference to the AWS S3 bucket name where logs will be stored

## Usage

Use this module to implement centralized logging using Loki with AWS S3 storage backend. It is especially useful for:

- Collecting and aggregating logs from AWS-hosted applications and services
- Leveraging AWS S3 for cost-effective, scalable log storage
- Implementing log retention policies with S3 lifecycle management
- Supporting observability and monitoring workflows in AWS environments
- Integrating with existing AWS logging and monitoring infrastructure
- Providing durable and highly available log storage using AWS S3
