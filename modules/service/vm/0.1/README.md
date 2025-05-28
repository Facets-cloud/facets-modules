# VM Flavor Service Module

## Overview

This module defines a service with the `vm` flavor, suitable for deploying application workloads on virtual machines across AWS and GCP. It supports build and deployment strategy configuration, autoscaling, resource sizing, and runtime health checks. This flavor is ideal for applications that require VM-level granularity for performance, isolation, or legacy dependency needs.

## Configurability

- **Cloud Support**: Compatible with AWS and GCP.
- **Metadata**: Custom labels can be added to describe or control behavior.
- **Host Affinity**: Option to enable/disable host anti-affinity.
- **Release Settings**:
  - Artifactory and app name configuration
  - Deployment strategy: `RollingUpdate`
- **Runtime Configuration**:
  - **Health Checks**: Define liveness check URL, port, timeout, period, and startup time
  - **Ports**: Define service and protocol (`TCP` in this case)
  - **Autoscaling**: Configure min/max replicas and CPU threshold
  - **Command**: Define startup or bootstrap commands
  - **Size**: Specify instance type (e.g., `t4g.nano`)
- **Environment Variables**: Custom environment variables (`foo`, `dummy`) can be defined

## Usage

1. **Set Flavor**: Ensure the service flavor is set to `vm`.
2. **Metadata**: Add labels and schema reference as needed.
3. **Disable Service (Optional)**: Use `disabled: true` if the service should be inactive.
4. **Configure Spec**:
   - Set `type` to `application`
   - Define build source (artifactory and app name)
   - Choose a strategy like `RollingUpdate`
5. **Runtime Settings**:
   - Health check endpoints and timing
   - Container port mappings
   - Autoscaling thresholds
   - Startup commands
   - VM size specification
6. **Environment Variables**: Add required key-value pairs for runtime configuration.

> Example Port Configuration:
> - HTTP: Port `50051`, Protocol `TCP`
