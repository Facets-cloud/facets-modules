# Elasticsearch - Kubernetes Flavor

## Overview

This module provides a Kubernetes-based Elasticsearch deployment configuration supporting major cloud platforms including AWS, Azure, GCP, and native Kubernetes clusters. It enables users to specify the Elasticsearch version and customize resource allocation per instance to meet various workload requirements. The sizing configuration includes CPU, memory, volume, and instance count, ensuring flexible and scalable Elasticsearch clusters.

## Configurability

- **Elasticsearch Version:** Select from supported versions to align with application compatibility and feature needs.  
- **CPU and CPU Limit:** Specify the number of CPU cores required, ensuring the requested CPU does not exceed the limit and that limits are not set below requested values.  
- **Memory and Memory Limit:** Define memory allocations similarly, with pattern validation and limit enforcement.  
- **Volume:** Set storage size per instance with format validation.  
- **Instance Count:** Determine how many Elasticsearch instances to deploy, with configurable minimum and maximum boundaries.  

All resource values are validated against predefined patterns to guarantee correct formatting and consistency between requests and limits. This configuration ensures efficient resource utilization and stable Elasticsearch deployments.

## Usage

Users define the Elasticsearch version from a set of supported versions and provide sizing parameters to control compute and storage resources for each Elasticsearch node. The configuration supports validation rules to maintain consistency between requested resources and their limits, preventing misconfiguration. This module can be enabled or disabled as needed.
