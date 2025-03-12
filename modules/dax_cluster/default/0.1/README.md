# DAX Cluster Module

This module creates an Amazon DynamoDB Accelerator (DAX) cluster on AWS, including the necessary IAM roles, security groups, parameter groups, and subnet groups. It is designed to be used within the Facets framework, providing a powerful and efficient caching solution for DynamoDB.

## Functionality

- Creates a DAX cluster with specified configurations.
- Configures IAM roles and policy attachments.
- Sets up DAX parameter groups.
- Defines security groups and subnet groups.

## Configurability

- **Node Type**: Specify the node type for DAX cluster.
- **Replication Factor**: Define the replication factor for the cluster.
- **Cluster Endpoint Encryption**: Specify the encryption type for cluster endpoint.
- **Availability Zones**: Set the availability zones for the cluster.
- **Description**: Provide a description for the DAX cluster.
- **Notification Topic ARN**: Set the notification topic ARN.
- **Maintenance Window**: Define the maintenance window for the cluster.
- **Security Groups**: Configure security groups for the cluster.
- **Server-Side Encryption**: Enable or disable server-side encryption for the cluster.