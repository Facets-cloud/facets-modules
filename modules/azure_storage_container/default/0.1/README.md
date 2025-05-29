# Azure Storage Container Module

## Overview

The Azure Storage Container module provisions and manages blob storage containers within Azure Storage Accounts. It provides a declarative configuration interface to create secure, scalable, and cost-efficient storage buckets for unstructured data. This module is ideal for storing application logs, media files, backups, and other large datasets in Azure-native environments.

## Configurability

- **Container name**: Set via the `metadata.name` field.
- **Access type**: Configure public or private access to the container (`access_type`: `private`, `blob`, or `container`).
- **Lifecycle management**: Define rules for automatic tiering and deletion, such as:
  - `tier_to_cool_after_days`: Move blobs to cool storage after N days.
  - `tier_to_archive_after_days`: Move blobs to archive after N days.
  - `delete_after_days`: Delete blobs after N days.
  - `snapshot_delete_after_days`: Delete snapshots after N days.
  
## Usage

This module is useful for teams looking to automate the creation of Azure Storage containers within CI/CD pipelines or infrastructure management systems.

Common use cases:

- Storing large volumes of binary or log data  
- Supporting media streaming, backup, or archive scenarios  
- Integrating with serverless functions or microservices that need blob access  
- Managing data isolation across dev, staging, and production environments
