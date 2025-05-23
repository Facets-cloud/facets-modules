# DAX Cluster - Default Flavor

## Overview

The `dax_cluster` intent with the `default` flavor provisions an Amazon DynamoDB Accelerator (DAX) cluster. DAX is a fully managed, in-memory cache for DynamoDB that delivers fast read performance for applications. This flavor supports specifying cluster size, replication, and associated IAM policies, making it suitable for enhancing performance in read-heavy workloads.

## Configurability

- **size.instance** (`string`):  
  Defines the instance type to be used for each node in the DAX cluster (e.g., `dax.r4.large`).

- **replication_factor** (`integer`):  
  Specifies the number of nodes in the cluster (must be between 1 and 11).

- **iam_policies** (`string`):  
  ARN of the IAM policy to be associated with the DAX cluster for access permissions.

## Usage

Use this flavor to deploy a scalable and high-performance DAX cluster integrated with DynamoDB on AWS. It simplifies configuration through declarative inputs and supports automatic association with VPCs. Define the instance size and replication factor to suit performance and availability needs, while IAM policies ensure secure access control.
