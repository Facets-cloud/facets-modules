# Log Collector – Kubernetes Flavor (v0.1)

## Overview

The `log_collector - k8s` flavor (v0.1) enables the collection and management of logs within Kubernetes environments. This module integrates with Loki to provide structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS  
- GCP  
- Azure  
- Kubernetes

## Configurability

### Spec

#### `retentation_days` (`integer`)

Defines the number of days logs are retained.

#### `storage_size` (`string`)

Specifies the size of the storage allocated for logs.

---

### Advanced Configuration

#### `loki` (object)

Provides advanced configuration options for Loki, including settings for the ruler, server, ingester, schema, compactor, querier, ingester client, and limits.

- **ruler**:
  - `storage`:
    - `type`: Type of storage (e.g., local).
    - `local`: Local storage configuration.
    - `rule_path`: Path for storing rules.
    - `alertmanager_url`: URL for the Alertmanager.
    - `ring`: Configuration for the ring.
    - `enable_api`: Enables the API.
    - `enable_alertmanager_v2`: Enables Alertmanager v2.
- **server**:
  - `http_server_read_timeout`: HTTP server read timeout.
  - `http_server_write_timeout`: HTTP server write timeout.
  - `http_server_idle_timeout`: HTTP server idle timeout.
- **ingester**:
  - `chunk_target_size`: Target size for chunks.
  - `chunk_encoding`: Encoding for chunks.
  - `max_chunk_age`: Maximum age for chunks.
  - `chunk_idle_period`: Idle period for chunks.
- **schema_config**:
  - `configs`: Schema configuration.
- **compactor**:
  - `working_directory`: Working directory for the compactor.
  - `shared_store`: Shared store configuration.
  - `compaction_interval`: Interval for compaction.
- **querier**:
  - `query_timeout`: Timeout for queries.
  - `engine`: Configuration for the query engine.
- **ingester_client**:
  - `grpc_client_config`: Configuration for the gRPC client.
- **limits_config**:
  - `max_global_streams_per_user`: Maximum global streams per user.
  - `split_queries_by_interval`: Interval for splitting queries.
  - `max_query_parallelism`: Maximum query parallelism.

#### `minio` (object)

Provides configuration options for MinIO, including provisioning commands.

#### `promtail` (object)

Provides configuration options for Promtail, including settings for scraping kubelet logs and additional matches.

#### `loki_canary` (object)

Provides configuration options for Loki Canary, including enabling the canary and node selector settings.

---

## Usage

Use this module to collect and manage logs in Kubernetes environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
