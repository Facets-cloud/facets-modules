# TCP Load Balancer Module - NLB Flavor v0.2

A multi-cloud Terraform module for deploying TCP/UDP load balancers with support for AWS, GCP, Azure, and Kubernetes. This module creates network load balancers that can distribute traffic across backend applications using configurable port mappings and selector-based routing.

## Overview

This module deploys TCP/UDP load balancers across multiple cloud platforms using a unified configuration interface. It supports both single-instance load balancing for centralized traffic distribution and per-instance load balancing for targeting specific backend applications. The module handles port exposure, protocol configuration, and backend service discovery through Kubernetes selectors.

## Configurability

The module provides flexible configuration options through the `spec` block:

- **Load Balancing Mode**: Choose between `loadbalancing` for single instance traffic distribution or `per_instance` for targeting specific backend applications
- **Instance Management**: Configure the number of load balancer instances to create when using per-instance mode (required for per_instance mode)
- **Port Configuration**: Define multiple named ports with TCP/UDP protocol support using pattern-based port definitions
- **Network Visibility**: Control load balancer accessibility with private/public boolean configuration
- **Backend Selection**: Use Kubernetes selector maps with YAML editor support to define which applications receive traffic
- **Multi-Cloud Support**: Deploy consistently across AWS, GCP, Azure, and Kubernetes environments

Key configurable parameters include named port mappings with unique port constraints, string-based protocol specification (tcp/udp), boolean private/public access control, and YAML-based selector configuration for precise backend targeting.

## Usage

This module operates independently without requiring specific input dependencies from other modules, making it suitable for standalone load balancer deployments across different cloud environments.

Once configured and deployed:
- The TCP/UDP load balancer will be created in the target cloud environment with specified named port configurations.
- Traffic will be distributed to backend applications based on the configured Kubernetes selectors.
- The load balancer will expose services on the defined ports using the specified protocols (TCP/UDP).
- Any updates to port configuration, selector mappings, or instance count will trigger an update of the load balancer configuration.
