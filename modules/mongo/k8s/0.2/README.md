# MongoDB Kubernetes Flavor Documentation (v0.2)

## Overview

The `mongo - k8s` flavor (v0.2) provisions a MongoDB deployment inside a Kubernetes cluster. This option is ideal for users who want full control of their MongoDB lifecycle, resources, and deployment configuration within their Kubernetes infrastructure.

This flavor is compatible with **AWS**, **Azure**, **GCP**, and **Kubernetes** environments.

## Configurability

### Required Fields

- **authenticated** (`boolean`)  
  Indicates whether to enable authentication for the MongoDB instance.

- **mongodb_version** (`string`)  
  Specifies the version of MongoDB to deploy. Supported values include:
  - `4.4.15`
  - `5.0.24`
  - `6.0.13`
  - `7.0.11`
  - `7.0.14`
  - `8.0.1`

- **size** (`object`)  
  Resource and scaling configuration for the MongoDB cluster.

  #### Nested Fields in `size`:
  - **instance_count** (`integer`)  
    Number of MongoDB instances to run (between 1 and 10).

  - **cpu** (`string`)  
    CPU request per instance. Values accepted:
    - Absolute: `1`, `2`, ..., `32`
    - Mils: `500m`, `1000m`, ..., `32000m`

  - **memory** (`string`)  
    Memory request per instance. Valid units:
    - GiB: `1Gi` to `64Gi`
    - MiB: `1Mi` to `64000Mi`

  - **cpu_limit** (`string`)  
    CPU limit must be ≥ `cpu`.

  - **memory_limit** (`string`)  
    Memory limit must be ≥ `memory`.

  - **volume** (`string`)  
    Size of persistent volume in format like `10Gi`.

## Usage

Use this flavor when:

- Deploying MongoDB **inside Kubernetes** clusters with platform-managed storage and compute.
- Managing **resource requests and limits** tightly for performance and cost control.
- Needing support for **multi-instance configurations** (replica sets or sharded clusters).
