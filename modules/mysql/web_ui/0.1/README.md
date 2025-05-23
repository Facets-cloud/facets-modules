# MySQL Web UI Flavor Documentation

## Overview

The `mysql_web - k8s` flavor provides a graphical user interface (GUI) for MySQL users to log in and manage their databases through a web-based interface. This Kubernetes-native deployment supports multiple cloud providers including AWS, Azure, GCP, and generic Kubernetes clusters.

## Configurability

### MySQL Web UI Version

Specify the version of the MySQL Web UI to deploy, for example:
- `5.2.1-debian-12-r35`

### Size Configuration

Configure resource sizing for the MySQL Web UI pods:

- **CPU**: Number of CPU cores or millicores (e.g., `500m` or `1`)
- **Memory**: Amount of memory allocated (e.g., `800Mi` or `1.5Gi`)
- **CPU Limit**: CPU upper limit for the container
- **Memory Limit**: Memory upper limit for the container

All CPU and memory values support a range validated by specific patterns to ensure proper Kubernetes resource definitions.

### Metadata

- **Namespace**: Kubernetes namespace where the MySQL Web UI will be deployed (default: `default`)

## Usage

This flavor is ideal for teams that want an easy-to-use web-based MySQL management interface integrated directly into their Kubernetes deployments. It allows database users to interact with MySQL without needing CLI access or external tools.

- Specify the UI version to align with your compatibility and feature needs.
- Tune CPU and memory allocations to balance performance and cost.
- Deploy in any supported Kubernetes namespace for isolation and organization.
- Supports deployment across major cloud providers, making it flexible for hybrid or multi-cloud setups.

## Cloud Providers

- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (Generic)**
