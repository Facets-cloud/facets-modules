# MySQL RDS Flavor Documentation

## Overview

The `mysql - rds` flavor enables deployment and management of MySQL using AWS RDS (Relational Database Service). It supports choosing MySQL versions and configuring instance types for writer and reader nodes, optimized for AWS infrastructure. This flavor focuses exclusively on the AWS cloud environment.

## Configurability

### MySQL Version

Supported MySQL versions:
- `8.0`
- `5.7`

### Size Configuration

#### Writer Node Configuration
Select an AWS RDS instance type for the writer node:
- Examples: `db.t4g.medium`, `db.t3.medium`, `db.t3.small`, `db.t3.micro`, `db.t3.large`, etc.

#### Reader Node Configuration
Configure reader nodes with:
- Instance type (same options as writer)
- Instance count (number of reader replicas, 0 to 20)

### Apply Immediately

Boolean flag to specify whether configuration changes should apply immediately or during the next maintenance window. Default is `false`.

## Usage

This flavor is designed for users who want to run MySQL on AWS managed infrastructure via RDS, leveraging the scalability, reliability, and managed service features of AWS.

- Choose your MySQL version according to application compatibility and feature needs.
- Select instance types that balance cost and performance requirements for writer and reader nodes.
- Set the number of read replicas to optimize read scaling and availability.

This flavor is ideal for teams who want to focus on application development while offloading operational complexity of MySQL maintenance, backups, and patching to AWS RDS.

## Cloud Providers

- **AWS**
