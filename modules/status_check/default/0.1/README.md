# TCP Loadbalancer - NLB Flavor

## Overview

The `tcp_lb` intent with the `nlb` flavor provides a way to create TCP and UDP load balancers across major cloud platforms such as GCP, Kubernetes, Azure, and AWS. It supports both shared load balancing and per-instance modes to handle different backend routing needs. This flavor is designed for applications requiring low-latency, stable network connections. It abstracts infrastructure details, enabling consistent load balancing across environments.

## Configurability

Key options include the `mode`, which controls whether the load balancer is shared or dedicated per instance, and `instances` to specify how many backends to target in per-instance mode. The `ports` section lets you define multiple named ports with associated protocols (TCP or UDP). The `private` flag toggles whether the load balancer is internet-facing or restricted to internal networks. Kubernetes `selector` labels map load balancers to specific backend workloads dynamically.

## Usage

This flavor is ideal for exposing TCP/UDP services that need direct access, such as custom protocols or stateful applications. It supports both public and private deployments depending on the `private` setting. When running in Kubernetes, selectors ensure traffic reaches the intended pods or services. The flexibility in ports and modes makes it suitable for multi-tenant systems, internal APIs, or multi-cloud deployments needing consistent Layer 4 traffic management.

