# Log Collector – Loki Standalone Kubernetes Flavor (v0.1)

## Overview

The `log_collector - loki_standalone_k8s` flavor (v0.1) enables the collection and management of logs using Loki in a standalone setup within Kubernetes environments. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS  
- Azure  
- GCP  
- Kubernetes

## Configurability

### Inputs

#### `kubernetes_details`

- **Type**: `@output/kubernetes`
- **Display Name**: Kubernetes Cluster
- **Description**: The details of the Kubernetes cluster where the Loki standalone will be installed
- **Optional**: `false`
- **Default**:
  - `resource_type`: `kubernetes_cluster`
  - `resource_name`: `default`

### Spec

#### `title` (`string`)

Title of the Loki Configuration.

#### `type` (`string`)

Type of the Loki Configuration.

#### `properties` (`object`)

Configuration properties for Loki, Minio, and Promtail.

##### `loki` (object)

Provides configuration options for Loki.

- **replicas** (`integer`): Number of Loki replicas.
  - **Title**: Replicas
  - **Description**: Number of Loki replicas
  - **Minimum**: 1
  - **Maximum**: 10
  - **UI Placeholder**: "Enter replicas (e.g., 2)"
  - **UI Error Message**: "Replicas must be between 1 and 10."
- **volume** (`string`): Storage volume for Loki.
  - **Title**: Volume
  - **Description**: Storage volume for Loki
  - **Pattern**: "^[0-9]+(\\.[0-9]+)?Gi$"
  - **UI Placeholder**: "e.g., '5Gi' or '10Gi'"
  - **UI Error Message**: "Volume must be in the format 'XGi' (e.g., '5Gi')."
- **loki_standalone** (object): Configuration for Loki standalone.
  - **timeout** (`integer`): Timeout for deployment.
    - **Title**: Timeout
    - **Description**: "Timeout for deployment."
    - **Minimum**: 300
    - **Maximum**: 1800
    - **UI Placeholder**: "Enter timeout in seconds (e.g., 700)"
    - **UI Error Message**: "Timeout must be between 300s (5m) and 1800s (30m)."
  - **wait** (`boolean`): Wait for deployment completion.
    - **Title**: Wait
    - **Description**: "Wait for deployment completion."
  - **recreate_pods** (`boolean`): Recreate pods during updates.
    - **Title**: Recreate Pods
    - **Description**: "Recreate pods during updates."
  - **version** (`string`): Version for Loki Helm chart.
    - **Title**: Version
    - **Description**: "Loki chart version"
  - **values** (`object`): Overrides for Loki configuration.
    - **Title**: Custom Values
    - **Description**: Overrides for Loki configuration
    - **UI YAML Editor**: `true`

##### `minio` (object)

Provides configuration options for Minio.

- **replicas** (`integer`): Number of Minio replicas.
  - **Title**: Replicas
  - **Description**: Number of Minio replicas
  - **Minimum**: 1
  - **UI Placeholder**: "Enter replicas (e.g., 2)"
  - **UI Error Message**: "Replicas must be between 1 and 10."
- **volume** (`string`): Storage volume for Minio.
  - **Title**: Volume
  - **Description**: Storage volume for Minio
  - **Pattern**: "^[0-9]+(\\.[0-9]+)?Gi$"
  - **UI Placeholder**: "e.g., '10Gi' or '20Gi'"
  - **UI Error Message**: "Volume must be in the format 'XGi' (e.g., '10Gi')."
- **auth** (object): Authentication configuration for Minio.
  - **rootUser** (`string`): Username for Minio root access.
    - **Title**: Root User
    - **Description**: Username for Minio root access
    - **UI Placeholder**: "Enter root user (e.g., 'facets-user')"
  - **rootPassword** (`string`): Password for Minio root access.
    - **Title**: Root Password
    - **Description**: Password for Minio root access
    - **UI Placeholder**: "Enter root password"
- **values** (`object`): Overrides for Minio configuration.
  - **Title**: Custom Values
  - **Description**: Overrides for Minio configuration
  - **UI YAML Editor**: `true`

##### `promtail` (object)

Provides configuration options for Promtail.

- **timeout** (`integer`): Timeout for deployment.
  - **Title**: Timeout
  - **Description**: "Timeout for deployment (default: 600)"
  - **Minimum**: 300
  - **Maximum**: 1800
  - **UI Placeholder**: "Enter timeout in seconds."
  - **UI Error Message**: "Timeout must be between 300s (5m) and 1800s (30m)."
- **wait** (`boolean`): Wait for deployment completion.
  - **Title**: Wait
  - **Description**: "Wait for deployment completion."
- **recreate_pods** (`boolean`): Recreate pods during updates.
  - **Title**: Recreate Pods
  - **Description**: "Recreate pods during updates."
- **version** (`string`): Version for Promtail Helm chart.
  - **Title**: Version
  - **Description**: "Promtail chart version (default: 6.7.4)"
  - **UI Placeholder**: "Select a version"
- **values** (`object`): Overrides for Promtail configuration.
  - **Title**: Custom Values
  - **Description**: Overrides for Promtail configuration
  - **UI YAML Editor**: `true`

---

## Usage

Use this module to collect and manage logs using Loki in a standalone setup within Kubernetes environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
