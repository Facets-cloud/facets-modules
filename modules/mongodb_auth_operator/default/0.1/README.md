# MongoDB Auth Operator Flavor Documentation

## Overview

The `mongodb_auth_operator - default` flavor deploys the MongoDB authentication operator to manage MongoDB user authentication within Kubernetes clusters. This flavor supports deployments on major cloud providers as well as generic Kubernetes environments.

## Configurability

### Size Configuration

Define resource limits for the MongoDB Auth Operator:

- **CPU Limit**: The CPU limit allocated to the operator instance.  
  Acceptable values range from 1 to 32 cores or millicores (e.g., `100m`, `1`, `32`).

- **Memory Limit**: The memory limit allocated to the operator instance.  
  Acceptable values range from 1Mi to 64Gi (e.g., `100Mi`, `1Gi`, `64Gi`).

Both CPU and memory limits must conform to specified regex patterns to ensure Kubernetes compliance.

### Values Configuration

A YAML object containing custom values passed to the underlying Helm chart, allowing advanced customization of the MongoDB Auth Operator deployment.

### Kubernetes Details

Specify the Kubernetes cluster details where the MongoDB Auth Operator will be installed. This is mandatory and typically references a Kubernetes cluster resource.

## Usage

Use this flavor to deploy a managed MongoDB authentication operator in your Kubernetes environment, which simplifies and centralizes MongoDB user and role management securely.

- Set CPU and memory limits based on your environment's load and resource availability.
- Use the YAML values input for advanced configuration of the Helm chart, including any overrides or custom settings.
- Deploy on any supported cloud platform or Kubernetes environment by specifying the appropriate cluster details.

## Cloud Providers

- **AWS**  
- **Azure**  
- **GCP**  
- **Kubernetes (Generic)**
