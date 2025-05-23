# Log Collector – Loki Standalone S3 Flavor (v0.1)

## Overview

The `log_collector - loki_standalone_s3` flavor (v0.1) enables the collection and management of logs using Loki in a standalone setup with AWS S3 storage. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS

## Configurability

### Inputs

#### `kubernetes_details`

- **Type**: `@outputs/kubernetes`
- **Default**:
  - `resource_type`: `kubernetes_cluster`
  - `resource_name`: `default`

### Spec

#### `title` (`string`)

Title of the Loki Configuration.

#### `type` (`string`)

Type of the Loki Configuration.

#### `properties` (`object`)

Configuration properties for Loki, AWS S3, and Promtail.

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

##### `aws_s3` (object)

Provides configuration options for AWS S3.

- **bucket_names** (object): S3 bucket names for Loki storage.
  - **Title**: Bucket Names
  - **Description**: S3 bucket name for Loki storage
  - **Required**: ["chunks", "ruler"]
  - **Properties**:
    - **chunks** (`string`): S3 bucket name for Loki chunks storage.
      - **Title**: Chunks Bucket
      - **Description**: S3 bucket name for Loki chunks storage
      - **UI Placeholder**: "Enter chunks bucket name (e.g., 'chunk-bucket-loki-nlqkbnwmkq')"
      - **UI Error Message**: "Bucket name must contain only lowercase letters, numbers, and hyphens."
      - **UI API Source**:
        - **Endpoint**: "/cc-ui/v1/dropdown/stack/{{stackName}}/resources-info"
        - **Method**: GET
        - **Params**:
          - `includeContent`: false
        - **Label Key**: resourceName
        - **Value Key**: resourceName
        - **Value Template**: "${s3.{{value}}.out.attributes.bucket_name}"
        - **Filter Conditions**:
          - **Field**: resourceType
          - **Value**: s3
    - **ruler** (`string`): S3 bucket name for Loki ruler storage.
      - **Title**: Ruler Bucket
      - **Description**: S3 bucket name for Loki ruler storage
      - **UI Placeholder**: "Enter ruler bucket name (e.g., 'ruler-bucket-loki-nlqkbnwmkq')"
      - **UI Error Message**: "Bucket name must contain only lowercase letters, numbers, and hyphens."
      - **UI API Source**:
        - **Endpoint**: "/cc-ui/v1/dropdown/stack/{{stackName}}/resources-info"
        - **Method**: GET
        - **Params**:
          - `includeContent`: false
        - **Label Key**: resourceName
        - **Value Key**: resourceName
        - **Value Template**: "${s3.{{value}}.out.attributes.bucket_name}"
        - **Filter Conditions**:
          - **Field**: resourceType
          - **Value**: s3

##### `promtail` (object)

Provides configuration options for Promtail.

- **timeout** (`integer`): Timeout for deployment.
  - **Title**: Timeout
  - **Description**: "Timeout for deployment (default: 600)"
  - **Minimum**: 300
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
  - **Description**: "Promtail chart version"
  - **UI Placeholder**: "Select a version"
- **values** (`object`): Overrides for Promtail configuration.
  - **Title**: Custom Values
  - **Description**: Overrides for Promtail configuration
  - **UI YAML Editor**: `true`

---

## Usage

Use this module to collect and manage logs using Loki in a standalone setup with AWS S3 storage. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
