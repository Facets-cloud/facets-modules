# Kafka MSK Module (`flavor: msk`, `version: 0.1`)

## Overview

This module provisions a **Kafka cluster using AWS Managed Streaming for Apache Kafka (MSK)**. It allows you to define authentication, Kafka version, instance sizing, storage volume, and replication count. This is ideal for production workloads requiring high availability and managed Kafka infrastructure on AWS.

## Configurability

The Kafka MSK module requires the following fields in the `spec` block.

---

**`spec`**

- **`authenticated`**: 
Whether to enable password-based authentication (SASL/SCRAM).

**`kafka_version`**: 
Kafka version to deploy. Supported values include:

- `1.1.1`, `2.1.0`, `2.2.1`, `2.3.1`, `2.4.1`, `2.4.1.1`, `2.5.1`, `2.6.0`, `2.6.1`, `2.6.2`, `2.6.3`
- `2.7.0`, `2.7.1`, `2.7.2`, `2.8.0`, `2.8.1`, `2.8.2-tiered`
- `3.1.1`, `3.2.0`, `3.3.1`, `3.3.2`, `3.4.0`, `3.5.1`, `3.6.0`, `3.7.1`, `3.8.0`

**`persistence_enabled`**:
While MSK manages persistence internally, this field can be used to toggle volume size logic in the specification.

---

**size.kafka**

Defines the infrastructure configuration for Kafka brokers.

- `instance`:  
  The EC2 instance type to be used for Kafka brokers.  
  Supported values include:  
  `kafka.t3.small`, `kafka.m5.large`, `kafka.m7g.large`, `kafka.m5.xlarge`, etc.

- `instance_count`: 
  Number of Kafka broker nodes to deploy (0–20).

- `volume`: 
  Storage volume size in GiB. Example: `10Gi`, `100Gi`.  
  Must match the required format (integer + `Gi`).

---

## Usage

Once the resource is configured:

- A Kafka MSK cluster is provisioned with the specified number of broker instances.
- Each broker will use the chosen instance type and volume configuration.
- If `authenticated` is set to true, the cluster will use SASL/SCRAM authentication.
- This cluster can then be consumed by other services via Kafka clients or integrations.



