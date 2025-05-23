# OpenSearch Module for Elasticsearch Intent (v0.1)

## Overview

This module provides the OpenSearch flavor of the Elasticsearch intent, designed for deployment on AWS cloud environments. It enables configuration of OpenSearch clusters with specific Elasticsearch versions and customizable sizing parameters. This module supports selecting from various OpenSearch-compatible Elasticsearch versions and a broad range of instance types, allowing flexible and scalable cluster provisioning tailored to workload requirements.

## Configurability

The module configuration exposes the following key properties:

- **elasticsearch_version:**  
  Specifies the OpenSearch-compatible Elasticsearch version to deploy. Supported versions include `"7.10"`, `"6.8"`, `"5.6"`, `"2.3"`, and `"1.5"`.  
  *Refer to the official AWS OpenSearch documentation for detailed version information:*  
  https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html

- **size:**  
  Defines the datastore sizing parameters, including:  
  - **instance:** Select the EC2 instance type for the OpenSearch nodes. A comprehensive list of instance types is supported, ranging from general purpose (e.g., `m5.large.elasticsearch`) to memory-optimized (e.g., `r5.large.elasticsearch`) and storage-optimized (e.g., `i3.large.elasticsearch`).  
  - **instance_count:** Number of OpenSearch instances (nodes) to provision. Valid values range from 1 to 20.  
  - **volume:** Size of the storage volume attached to each instance. Must follow the pattern of a number followed by "G" or "Gi" (e.g., `100Gi`).

Validation ensures correct input types, valid selection from enumerations, and adherence to patterns for volume sizes.

## Usage

To deploy an OpenSearch cluster using this module, define the `elasticsearch_version` and sizing under the `spec` section. Choose the desired Elasticsearch version compatible with OpenSearch and configure the instance type, number of nodes, and storage volume size. This configuration enables provisioning of an OpenSearch cluster optimized for your workload needs on AWS infrastructure.


