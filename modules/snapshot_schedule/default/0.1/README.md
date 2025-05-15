# Snapshot Schedule - Default Flavor

## Overview

The `snapshot_schedule` intent with the `default` flavor provides a way to automate snapshot creation for various cloud resources across multiple platforms including AWS, GCP, Azure, and Kubernetes. It is designed to schedule regular backups or snapshots of resources like Kafka clusters or other stateful services. This automation helps ensure data durability and facilitates disaster recovery by managing snapshot lifecycles.

This flavor supports specifying the snapshot frequency, retention policies, and targeted resources. It integrates with existing resource management by linking snapshots to the resource type and name, enabling seamless backup orchestration.

## Configurability

The schema exposes the following key properties under the `spec` section:

### schedule

- **Type:** `string`
- **Description:**  
  Defines the cron-style schedule expression for when snapshots should be created. Common formats like `@hourly`, `@daily`, or custom cron expressions are supported. This controls the periodic execution of snapshot tasks.

### retention_policy

- **Type:** `object`
- **Description:**  
  Specifies rules for retaining snapshots to manage storage and compliance.
- **Properties:**
  - `expiry`: Duration string (e.g., `2160h` for 90 days) defining how long snapshots should be kept before automatic deletion.
  - `count`: Integer specifying the maximum number of snapshots to retain. Older snapshots beyond this count will be pruned.

### resource_name

- **Type:** `string`
- **Description:**  
  The name of the resource for which snapshots are scheduled. This ties the snapshot schedule directly to a particular resource instance, such as a Kafka cluster.

### resource_type

- **Type:** `string`
- **Description:**  
  Specifies the type of resource that snapshots will be taken from, for example, `kafka`. This helps in correctly associating the snapshot task with the underlying resource technology.

### additional_claim_selector_labels

- **Type:** `object`
- **Description:**  
  Optional key-value map of labels to filter or target specific resource claims. This allows more granular selection when multiple resource instances exist, enhancing control over snapshot applicability.

### disabled

- **Type:** `boolean`
- **Description:**  
  Allows disabling the snapshot schedule without removing the configuration. Useful for temporary suspension or testing.

## Usage

This flavor is useful for automating backup operations across cloud environments for critical resources. Define the snapshot frequency with the `schedule` field and control how long snapshots are retained using the `retention_policy`. By specifying the `resource_name` and `resource_type`, snapshots are targeted precisely to the intended service instance. Optional label selectors allow further targeting refinement. This ensures reliable, repeatable backup scheduling with minimal manual intervention, aiding data protection strategies.
