# Kubernetes StatefulSet Service Module

## Overview

This module enables standardized deployment and management of stateful applications across AWS, Azure, GCP, and Kubernetes. It supports:

- Persistent volume management
- Stable network identities with ordered pod operations
- Multi-cloud compatibility with cloud-specific permissions
- Health checks, resource allocation, and deployment strategies
- Init containers and sidecars for enhanced functionality

Ideal for databases, distributed systems, or apps needing predictable storage and identity.

## Configurability

### Storage Configuration
- Define PVCs with access modes (`ReadWriteOnce`, `ReadWriteMany`), size, and mount paths
- Mount ConfigMaps, Secrets, PVCs, and HostPaths

### Deployment Settings
- Host anti-affinity to spread pods across nodes
- Liveness/readiness probes using HTTP, port, or exec
- Autoscaling with CPU/RAM thresholds
- CPU/memory requests and limits
- Configurable ports and protocols

### Cloud-Specific Permissions
- **AWS**: IAM with IRSA
- **GCP**: Role definitions with conditions
- **Azure**: Azure role assignments

### Advanced Features
- Init containers and sidecars
- Deployment strategies: `RollingUpdate`, `Recreate`
- Disruption policies for update resilience

## Usage

1. **Namespace**: Set the target namespace.
2. **Storage**: Configure persistent volumes per your app’s requirements.
3. **Resources**: Define CPU/memory requests and limits.
4. **Networking**: Set service/container ports.
5. **Health Checks**: Configure probes to ensure pod availability.

### Key Parameters
- PVCs: Access mode, size, mount path
- Runtime: Resources, ports, probes, autoscaling
- Release: Image version and strategy
- Cloud: Role/permission settings per platform
