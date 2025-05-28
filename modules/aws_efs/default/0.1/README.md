# AWS EFS Module

## Overview

This module provisions an Amazon Elastic File System (EFS). It is designed to help teams configure scalable, elastic NFS file storage that can be mounted on multiple compute instances or Kubernetes workloads within the AWS ecosystem.

The module supports encryption, throughput tuning, performance configuration, lifecycle policies, and tagging through the advanced configuration block.


## Configurability

- **`metadata`**: 
  Optional metadata for naming or identifying the EFS resource.

- The `spec` block is required by schema but currently unused.


You can customize the EFS setup using the `advanced.aws_efs` section. Below are the available configuration options:

- **`tags`**: A key-value map of tags to be assigned to the EFS filesystem.

- **`creation_token`**: A unique name (up to 64 characters) used to ensure idempotent file system creation. If not provided, Terraform auto-generates one.

- **`encrypted`**: A boolean flag indicating whether the file system should be encrypted. Defaults to `false`.

- **`kms_key_id`**: The ARN of the KMS key to be used for encryption. Required if `encrypted` is set to `true`.

- **`performance_mode`**: The performance mode for the EFS. Acceptable values are `generalPurpose` and `maxIO`.

- **`availability_zone_name`**: The name of the AWS Availability Zone in which to create the file system. This is used to create One Zone EFS.

- **`throughput_mode`**: Specifies the throughput mode. Options are `bursting` and `provisioned`.

- **`provisioned_throughput_in_mibps`**: The throughput (in MiB/s) to provision for the file system. This is applicable only if `throughput_mode` is set to `provisioned`.

- **`lifecycle_policy`**: Allows configuration of lifecycle management for files within the EFS:
  - `transition_to_ia`: Indicates the duration after which files should move to the Infrequent Access (IA) storage class. Supported values include `AFTER_7_DAYS`, `AFTER_14_DAYS`, `AFTER_30_DAYS`, `AFTER_60_DAYS`, and `AFTER_90_DAYS`.
  - `transition_to_primary_storage_class`: Defines when to move files back from IA to the primary storage class. Supported value is `AFTER_1_ACCESS`.

## Usage

This module is used to create a fully managed AWS EFS file system with optional lifecycle management and performance tuning. Once provisioned, it can be mounted by multiple EC2 instances or Kubernetes workloads using a PersistentVolumeClaim (PVC).

Typical use cases include:

- Shared storage between multiple pods or services.
- Persistent storage for stateful applications.
- Centralized logging or file-sharing system across clusters or compute groups.






