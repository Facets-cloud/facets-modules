# Snapshot Schedule - Default Flavor

## Overview

The `snapshot_schedule` intent with the `default` flavor automates snapshot creation for cloud resources (e.g., Kafka) across AWS, GCP, Azure, and Kubernetes. It ensures data durability through scheduled backups and retention policies.

## Configurability

- **schedule** (`string`): Cron-style schedule for snapshot timing (e.g., `@daily`, `0 0 * * *`).
- **retention_policy** (`object`): 
  - `expiry`: Duration to retain snapshots (e.g., `2160h`).
  - `count`: Max number of retained snapshots.
- **resource_name** (`string`): Name of the target resource (e.g., Kafka cluster).
- **resource_type** (`string`): Type of resource to snapshot (e.g., `kafka`).
- **additional_claim_selector_labels** (`object`, optional): Label filters for granular targeting.
- **disabled** (`boolean`): Toggle to enable/disable the schedule.

## Usage

Define `schedule`, `resource_name`, and `resource_type` to automate snapshots. Use `retention_policy` to manage storage. Optional label selectors allow fine-tuned targeting, supporting automated, reliable backup workflows.
