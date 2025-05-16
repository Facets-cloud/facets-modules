# Alert Group Module

## Overview

This module provisions an **alert group** that defines Prometheus alerting rules for monitoring the health and reliability of Kubernetes or cloud-native resources. These rules are evaluated by Prometheus and trigger alerts based on specified conditions such as pod crashes, replica mismatches, or other infrastructure failures.
Each rule defines an expression, severity level, message, summary, and resource context. Rules can also include additional labels and annotations to aid in filtering, alert routing etc. 

## Configurability

The configuration is specified under the `spec` field and supports defining one or more alert rules.

### ✅ metadata

- `metadata`: *(optional)*  
  Contains resource-level metadata such as a user-defined name or description.

### ✅ spec

- `rules`: *(object, required)*  
  A map of alerting rule definitions. Each key is a unique name for the rule (e.g., `KubernetesPodCrashLooping1`, `StatefulSetNonReadyPods1`). The value is an object defining the rule’s Prometheus expression, summary, message, labels, and annotations.

#### Rule Properties

Each rule supports the following fields:

- `expr`: *(string, required)*  
  The Prometheus expression that defines the alert condition.

- `for`: *(string, required)*  
  The duration for which the condition must persist before firing the alert. Example: `5m`, `15m`.

- `summary`: *(string, required)*  
  A short summary of the alert.

- `message`: *(string, required)*  
  The detailed message for the alert. Supports Go templating for dynamic content (e.g., `{{ $labels.instance }}`).

- `severity`: *(string, required)*  
  The severity level of the alert. Common values: `critical`, `warning`, `info`.

- `resource_name`: *(string, required)*  
  The resource name associated with the alert. Example: `{{ $labels.pod }}`.

- `resource_type`: *(string, required)*  
  The type of resource being alerted on. Example: `pod`, `statefulset`.

- `labels`: *(object, required)*  
  A map of key-value pairs used for grouping and routing alerts (e.g., `team: stack_owner`).

- `annotations`: *(object, required)*  
  A map of key-value pairs containing additional metadata or documentation for the alert.

## Usage

You can define multiple alerting rules in the spec.rules block, each with its own conditions, severity, and context.

## Notes
Each alert rule must have a unique name.

Expressions are written using PromQL and are evaluated by Prometheus.

You can use Go templating in message, summary, and other fields.

Labels and annotations are important for alert routing in systems like Alertmanager.



