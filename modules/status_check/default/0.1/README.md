# Status Check - Default Flavor

## Overview

The `status_check` intent with the `default` flavor provides a way to monitor the health and connectivity of services across multiple cloud platforms including AWS, GCP, Azure, and Kubernetes. It supports various protocols such as HTTP, MongoDB, Redis, and TCP. This flavor helps ensure that backend services are responsive and operating correctly.

## Configurability

The schema allows detailed configuration of different types of health checks under the `spec` section:

- **HTTP Checks**: Define one or more HTTP endpoints to verify. For each, specify the target URL, HTTP method (e.g., GET), and the expected HTTP status code to confirm service availability. Checks can be enabled or disabled individually, allowing flexible monitoring setups.

- **MongoDB Checks**: Multiple MongoDB connection strings can be monitored. Each MongoDB check includes a `url` for the database and a flag to enable or disable the check. This helps verify database accessibility and responsiveness.

- **Redis Checks**: Redis instances can be similarly monitored by providing connection URLs and toggleable check enablement. This ensures caching layers or message brokers remain reachable.

- **TCP Checks**: Raw TCP connectivity tests can be configured using host and port pairs in the URL format. This is useful for verifying availability of any TCP-based service, including custom protocols or secured endpoints.

Additionally, the entire status check resource can be globally disabled by setting the `disabled` flag at the root level. This provides easy control over whether monitoring is active without needing to adjust individual checks.

This level of configurability enables comprehensive health monitoring across multiple service types and protocols, supporting robust and flexible observability in cloud-native and hybrid environments.

## Usage

This flavor is useful for monitoring website availability, database connections, and network endpoints. It can be integrated into automated monitoring workflows to trigger alerts on failures. The flexible configuration allows targeting multiple services simultaneously and supports health verification in multi-cloud and Kubernetes environments.
