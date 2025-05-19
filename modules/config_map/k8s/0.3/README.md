# Kubernetes ConfigMap Module (v0.3)

## Overview

This module provisions and manages Kubernetes ConfigMaps with enhanced support for structured key-value data objects. It is designed for use across multiple cloud platforms including AWS, Azure, GCP, and Kubernetes environments.

## Configurability

- **Structured data objects**: Each ConfigMap entry is a structured object containing a `key` and `value`.  
- **Key validation**: Keys are validated against the pattern `^[a-zA-Z0-9_.-]*$` ensuring only alphanumeric characters, dots, underscores, and hyphens are allowed.  
- **Value field**: Values support multiline input through a textarea type for richer configuration content.  
- **Multi-cloud compatibility**: Supported on AWS, Azure, GCP, and Kubernetes-native platforms.  
- **Disable toggle**: ConfigMaps can be disabled easily via a `disabled` flag for flexible deployment management.  

## Usage

This module allows teams to define ConfigMaps with explicit key-value pairs as structured objects, improving validation and input consistency. Typical use cases include:

- Managing environment variables or configuration settings for Kubernetes workloads  
- Storing multiline or complex configuration values  
- Enforcing naming conventions for config keys to avoid errors  
- Integrating ConfigMap management into multi-cloud infrastructure-as-code pipelines
