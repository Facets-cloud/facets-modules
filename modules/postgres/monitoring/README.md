# PostgreSQL Monitoring Module

## Overview

The PostgreSQL Monitoring module adds robust monitoring capabilities to PostgreSQL deployments running on Kubernetes and various cloud platforms including AWS, Azure, and GCP. It enables declarative configuration of alerting rules to monitor critical PostgreSQL health metrics such as server availability, dead tuples, and connection counts. This module is designed to provide timely and actionable alerts to help maintain database reliability and performance.

## Configurability

- **Multi-cloud support**: Works with PostgreSQL instances deployed on Kubernetes clusters across AWS, Azure, GCP, and native Kubernetes environments.  
- **Alerting rules**: Configure multiple alert types with customizable settings including enabling/disabling, severity levels, alert intervals, and thresholds.  
- **PostgreSQL Down alert**: Detects when the PostgreSQL server is unreachable or down.  
- **Dead Tuples alert**: Monitors and alerts when the percentage of dead tuples exceeds a configured threshold, indicating potential need for vacuum or cleanup.  
- **Too Many Connections alert**: Tracks the percentage of maximum allowed connections in use and triggers alerts when exceeding thresholds.  
- **Alert interval formatting**: Supports flexible time duration formats (e.g., `10m`, `1h30m`, `500ms`) for alert evaluation intervals.  
- **Severity levels**: Categorize alerts by urgency to prioritize responses effectively.

## Usage

This module is ideal for teams running PostgreSQL on Kubernetes who need integrated monitoring and alerting as part of their database operations.

Common use cases:

- Automatically detecting and alerting on PostgreSQL service downtime  
- Monitoring database health metrics to prevent performance degradation  
- Configuring alerts to trigger based on customizable thresholds for dead tuples and connections  
- Integrating PostgreSQL monitoring into cloud-native Kubernetes environments  
- Enabling proactive database maintenance through automated notifications
