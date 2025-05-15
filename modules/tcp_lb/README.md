# TCP Loadbalancer - NLB Flavor

## Overview

The `tcp_lb` intent with the `nlb` flavor provides a declarative configuration for creating network load balancers that expose TCP or UDP ports. It is designed to support backend services requiring direct access via Layer 4 load balancing and is compatible across multiple cloud providers such as **Google Cloud Platform (GCP)**, **Kubernetes**, **Azure**, and **Amazon Web Services (AWS)**.

This flavor is particularly suitable for:

- Applications requiring low-latency TCP forwarding.
- Stateful services that are not easily terminated with standard Layer 7 protocols.
- Environments where service port visibility and direct traffic routing are required.
- Workloads hosted across multiple clouds that need consistent TCP load balancing semantics.

The `nlb` flavor is intended to abstract the complexity of underlying infrastructure, providing a consistent way to configure TCP-based load balancing behavior across different platforms.

---

## Configurability

The schema exposes the following configurable properties under the `spec` section:

### 1. **Mode**
- **Type**: `string`
- **Allowed Values**:
  - `loadbalancing`: A single load balancer targets one or more backend services.
  - `per_instance`: A dedicated load balancer is created per backend instance.
- **Description**: This defines how traffic is routed to backend applications. The `per_instance` mode is useful for isolated routing, such as in multi-tenant environments or services with strict resource boundaries.

### 2. **Instances**
- **Type**: `integer`
- **Applicable When**: `mode` is set to `per_instance`
- **Description**: Specifies the number of separate load balancers to be created. Each instance corresponds to a backend workload requiring an isolated load balancer.

### 3. **Ports**
- **Type**: `object`
- **Structure**:
  - Key: Arbitrary name for the port mapping (alphanumeric and symbols `_`, `.`, `-`)
  - Value: Contains:
    - `port`: Port number to expose on the load balancer.
    - `protocol`: One of `tcp` or `udp`.
- **Description**: Defines all the ports that need to be exposed for external access. Multiple port mappings can be defined to support different services or protocols under the same load balancer.

### 4. **Private**
- **Type**: `boolean`
- **Description**: When set to `true`, the load balancer is created without public exposure. It is only accessible within the VPC or private network of the cloud provider. This is useful for internal microservices, databases, and backend APIs not intended for internet access.

### 5. **Selector**
- **Type**: `object`
- **Format**: YAML key-value map
- **Description**: In Kubernetes environments, this maps the load balancer to specific services or pods using Kubernetes label selectors. The load balancer will route traffic only to workloads that match these selectors, ensuring traffic isolation and dynamic backend binding.

---

## Usage

This flavor can be used in both public and private network scenarios. Below are several common use cases demonstrating how it can be adapted:

###  **Public Web Services**
For exposing TCP-based services such as HTTP, MQTT, or custom protocols directly to the internet:
- Set `private: false`
- Define ports like `80`, `443`, or any application-specific port
- Use `loadbalancing` mode for shared traffic distribution

###  **Internal Backend Services**
To expose services within a private VPC or internal Kubernetes cluster:
- Set `private: true`
- Define appropriate selectors for intra-cluster service discovery
- Ideal for internal databases, Redis clusters, or private APIs

###  **Per-Tenant/Per-App Load Balancing**
For applications requiring dedicated load balancers:
- Set `mode: per_instance`
- Specify the number of instances
- Each load balancer can be isolated for scaling or network policy enforcement

###  **Multi-Port Service Deployment**
When a service requires multiple ports (e.g., a game server or a legacy app):
- Define each required port under the `ports` object
- Use both `tcp` and `udp` as necessary

### **Secure and Controlled Traffic Routing**
Use the `selector` field to tightly control traffic flow and restrict access to only intended services or pods. This improves security posture and traffic visibility in Kubernetes-based deployments.

---
