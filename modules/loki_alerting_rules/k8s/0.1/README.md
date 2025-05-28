# Loki Alerting Rules Module (K8s Flavor)

## Overview

The `loki_alerting_rules - k8s` flavor (v0.1) enables the creation and management of alerting rules for Loki-based log monitoring in Kubernetes environments. This module provides the ability to define custom alert conditions based on log patterns, error rates, and other log-derived metrics to proactively monitor application and infrastructure health.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Rules**: Collection of alerting rules with the following properties for each rule:
  - **Expression (expr)**: LogQL query expression that defines the alert condition
  - **Message**: Alert message template with support for label interpolation
  - **Summary**: Brief summary of the alert condition
  - **For**: Duration threshold before the alert fires
  - **Labels**: Custom labels for alert categorization (team, severity, etc.)
  - **Disabled**: Flag to enable/disable individual rules
  - **Resource Name**: Template for identifying the affected resource
  - **Resource Type**: Type of resource being monitored (e.g., app, service)

## Usage

Use this module to implement log-based alerting and monitoring for your applications and infrastructure. It is especially useful for:

- Monitoring error rates and anomalies in application logs
- Setting up proactive alerts based on log patterns and metrics
- Tracking performance indicators derived from log data
- Implementing custom alerting logic using LogQL expressions
- Categorizing and routing alerts based on severity and team ownership
- Supporting observability and incident response workflows
- Maintaining application health monitoring across multi-cloud Kubernetes environments
