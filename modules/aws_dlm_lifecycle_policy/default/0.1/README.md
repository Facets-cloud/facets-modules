# AWS DLM Lifecycle Policy Module

## Overview

This module provisions an **AWS Data Lifecycle Manager (DLM) Lifecycle Policy** to automate the creation, retention, and optional cross-region copy of EBS volume snapshots.

It supports both **interval-based** and **cron-based** snapshot scheduling, retention controls, and tagging. Cross-region snapshot copies can also be configured for disaster recovery or compliance.


## Configurability

The configuration consists of two main parts: `schedules` and `target_tags`.

---

**`schedules`**

This defines the policies for how and when snapshots should be taken. You can define multiple named schedules.

- **`copy_tags`**: 
  Whether to copy tags from the source volume to the snapshot.

- **`create_rule`**:  
  Defines when to create the snapshot.

  You must provide **either**:

  - `interval`, `interval_unit`, and `times`  
    Example:
    ```yaml
    create_rule:
      interval: 1
      interval_unit: HOURS
      times:
        - "07:00"
    ```

  **OR**

  - `cron_expression`  
    Example:
    ```yaml
    create_rule:
      cron_expression: "cron(15 10 ? * 6L *)"
    ```

- **`retain_rule`**:  
  Defines how many snapshots to retain:
  ```yaml
  retain_rule:
    count: 14

- **`cross_region_copy_rules`**:
  Allows replicating snapshots to another region:

- **`tags_to_add`**:
Tags to be added to the created snapshots:
```yaml
    tags_to_add:
        ManagedBy: Terraform
```

- **`target_tags`**: This defines the tag filters used to select EBS volumes for snapshot lifecycle automation:

## Usage

The module creates an AWS DLM policy targeting all volumes matching target_tags.

For each schedule:

Snapshots will be created based on the create_rule.

Snapshots will be retained as per retain_rule.

If specified, snapshots are copied to another region with cross_region_copy_rules.

Snapshots will have tags_to_add applied.

