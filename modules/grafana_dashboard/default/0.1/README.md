# Grafana Dashboard Module

## Overview

This module provisions a **Grafana dashboard** using a declarative specification in JSON format. It is primarily used to visualize metrics from sources such as **Prometheus** and enables platform teams to predefine standard monitoring dashboards across clusters and environments.

This module supports the following cloud platforms:
- AWS
- GCP
- Azure
- Kubernetes

---

## Configurability

The module expects a complete Grafana dashboard configuration under the `spec.dashboard` field. This must adhere to the [Grafana dashboard JSON model](https://grafana.com/docs/grafana/latest/dashboards/json-model/), which includes panels, rows, templating variables, data sources, time range, and layout information.

**`metadata`**

- `metadata`:  
  Contains resource-level metadata such as a user-defined name or description. Can be left empty.

**`spec`**

- **`dashboard`**:  
  The full dashboard definition in JSON format, compatible with the [Grafana dashboard schema](https://grafana.com/docs/grafana/latest/dashboards/json-model/).

**`Dashboard properties`**

Key fields within the dashboard JSON:
- **`title`**: The title of the dashboard.
- **`panels`**: An array of visual panels (e.g., stat, graph, table, row).
- **`datasource`**: The UID of the Prometheus (or other) datasource.
- **`templating.list`**: Allows filtering using template variables such as `cluster` or `namespace`.
- **`time`**: Default time range for the dashboard.
- **`refresh`**: Auto-refresh interval.
- **`uid`**: Optional unique identifier for the dashboard.

## Usage

Once the resource is created:

- A Grafana dashboard will be created inside the target Grafana instance configured with your monitoring stack.
- The dashboard supports multiple panels and PromQL queries, grouped logically under rows (e.g., CPU, Memory, Network, Storage).
- You can use template variables like `$cluster` and `$datasource` for dynamic selection across environments.
- Dashboard updates can be made by modifying the JSON definition and redeploying the module.