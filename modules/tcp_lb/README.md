# TCP Loadbalancer - NLB Flavor

## Overview

The `tcp_lb` intent with the `nlb` flavor provides a simple way to create TCP or UDP load balancers across cloud platforms like GCP, Kubernetes, Azure, and AWS. It supports low-latency, Layer 4 load balancing for backend services. This flavor works well for stateful apps or services needing direct network access and consistent behavior across clouds.

## Configurability

You can configure the load balancer mode (`loadbalancing` or `per_instance`), number of instances for per-instance mode, and which ports and protocols (TCP/UDP) to expose. The `private` flag controls whether the load balancer is public or internal-only. Kubernetes selectors can be used to bind the load balancer to specific backend workloads, enabling dynamic routing based on labels.

## Usage

Use this flavor to expose public-facing TCP/UDP services or internal backend applications securely. It supports dedicated load balancers per app or shared load balancing for multiple backends. You can expose multiple ports with different protocols simultaneously. Selectors help control traffic routing in Kubernetes environments, ensuring only intended workloads receive traffic.
