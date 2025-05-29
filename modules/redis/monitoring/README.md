# Redis Monitoring Module (Kubernetes)

## Overview

This Redis Monitoring module adds observability capabilities for Redis deployments on Kubernetes and other cloud platforms (AWS, Azure, GCP). It defines customizable alerting rules to track the health, stability, and performance of Redis instances. The module enables teams to proactively detect failures, resource exhaustion, and excessive connection usage.

## Configurability

- **Alerts**: Configurable set of monitoring alerts.

  - **Redis Down**  
    - **Disabled**: Toggle to enable or disable this alert.  
    - **Interval**: Time duration before the alert triggers (e.g., `10m`, `1m30s`).  
    - **Severity**: Defines the urgency (`critical`, `warning`).

  - **Redis Out of Configured Max Memory**  
    - **Disabled**: Toggle to enable or disable this alert.  
    - **Interval**: Time duration before the alert triggers.  
    - **Severity**: Urgency level of the alert.  
    - **Threshold**: Memory usage percentage at which the alert fires (0–100%).

  - **Redis Too Many Connections**  
    - **Disabled**: Toggle to enable or disable this alert.  
    - **Interval**: Alert trigger interval.  
    - **Severity**: Severity of the alert (`critical`, `warning`).  
    - **Threshold**: Number of Redis connections that triggers the alert (minimum 1).

## Usage

This module enables platform teams to plug in Redis monitoring alerts seamlessly across Kubernetes environments and major clouds. These alerts are meant to be integrated with observability stacks like Prometheus + Alertmanager, Datadog, or Cloud Monitoring.

Common use cases:

- Notifying on Redis instance unavailability in real time  
- Triggering alerts when Redis exceeds configured memory usage  
- Preventing outages caused by excessive client connections  
- Integrating Redis metrics into central dashboards and alerting pipelines
