# MySQL Monitoring Kubernetes Flavor Documentation

## Overview

The `mysql_monitoring - k8s` flavor adds monitoring capabilities to MySQL deployments running on Kubernetes clusters. It supports alerting on key MySQL operational metrics such as availability, connection saturation, and restarts. This flavor is compatible with AWS, Azure, GCP, and generic Kubernetes environments.

## Configurability

### Alerts Configuration

Define alert rules with customizable severity, intervals, and thresholds:

- **MySQL Down**
  - **Disabled**: Toggle alert on/off
  - **Interval**: Duration before triggering alert (e.g., `1m5s`)
  - **Severity**: `critical` or `warning`

- **MySQL Too Many Connections**
  - **Disabled**: Toggle alert on/off
  - **Interval**: Duration before triggering alert (e.g., `1m5s`)
  - **Severity**: `critical` or `warning`
  - **Threshold**: Percentage of max MySQL connections to trigger alert (0–100)

- **MySQL Restarted**
  - **Disabled**: Toggle alert on/off
  - **Interval**: Duration before triggering alert (e.g., `1m5s`)
  - **Severity**: `critical` or `warning`

### Cloud Providers

Compatible with:
- **AWS**
- **Azure**
- **GCP**
- **Kubernetes (Generic)**

## Usage

To effectively monitor your MySQL Kubernetes deployment, configure alerting rules tailored to your operational needs. Enable or disable specific alerts based on the criticality of the condition for your environment.

- Set appropriate intervals to balance timely detection with alert noise.
- Choose severity levels to categorize alerts for escalation or automated remediation workflows.
- Use thresholds for connection limits to catch saturation early before it impacts application performance.

This monitoring flavor integrates seamlessly with Kubernetes-native alerting and monitoring tools, allowing you to incorporate these alerts into your existing observability stack. By leveraging these alert configurations, you can proactively maintain MySQL availability, performance, and reliability within your cloud or on-prem Kubernetes clusters.
