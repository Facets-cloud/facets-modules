# MySQL Kubernetes Flavor Documentation

## Overview

The `mysql - k8s` flavor provides a Kubernetes-native deployment model for running MySQL on any CNCF-conformant Kubernetes cluster, including managed services across AWS, Azure, GCP, or on-prem Kubernetes environments. Versioned as `0.1`, this flavor allows fine-grained control over CPU, memory, and volume resources for both writer and reader nodes.

## Configurability

### MySQL Version

Choose from supported versions:
- `5.7.43`
- `8.0.34`
- `8.0.4`

_Current selection_: `8.0.4`

### Size Configuration

#### Writer Node Configuration
Configure resource requests and limits for the primary database node:

- **CPU**: `1`  
- **Memory**: `1Gi`  
- **CPU Limit**: `1`  
- **Memory Limit**: `1Gi`  
- **Volume**: `8G`

#### Reader Node Configuration
Supports horizontal scaling of read replicas. Includes resource limits to maintain efficiency:

- **CPU**: `200m`  
- **Memory**: `800Mi`  
- **CPU Limit**: `200m`  
- **Memory Limit**: `800Mi`  
- **Volume**: `8G`  
- **Instance Count**: `0`

### Cloud Providers

This flavor is compatible with the following platforms:
- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (Generic)**
