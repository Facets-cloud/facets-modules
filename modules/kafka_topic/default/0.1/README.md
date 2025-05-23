# Kafka Topic Module

## Overview

This Terraform module provisions one or more **Kafka topics** with configurable parameters such as replication factor, number of partitions, and topic-level configurations. It is designed to be **cloud-agnostic**, supporting Kafka clusters deployed on:
- AWS 
- GCP 
- Azure 
- Kubernetes 

The module supports batch topic creation using a structured map and is useful for platform teams managing multiple Kafka topics with varied configurations.

## Configurability

The following parameters are supported under the `spec` block:

**`topics`**  
A map where each key represents a unique topic identifier, and the value is a topic configuration object.
Each topic object supports the following fields:

  - **`topic_name`** 
    The name of the Kafka topic. Must match pattern: `^[a-zA-Z0-9_.-]*$`.

  - **`replication_factor`**  
    Number of topic replicas across brokers for redundancy.
 
   - **`partitions`**  
    Number of partitions for the topic. Determines parallelism and scalability.

   - **`configs`**  
    A key-value map of topic-level configuration overrides.
    - `retention.ms`: Message retention period in milliseconds.
    - `segment.ms`: Segment file flush interval.
    - `cleanup.policy`: Log compaction or deletion policy.

## Usage

This module provisions the following resources:

- **Kafka Topics** – One or more topics created in the Kafka cluster with the specified configuration.
- **Cloud Provider Independence** – Compatible with Kafka clusters hosted across AWS, GCP, Azure, and Kubernetes platforms.
- **Declarative Topic Management** – Easily define topic-level settings and enforce them declaratively.

