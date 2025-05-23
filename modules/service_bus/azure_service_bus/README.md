# Service Bus - Azure Service Bus Flavor

## Overview

The `service_bus` intent with the `azure_service_bus` flavor provides declarative configuration to provision and manage Azure Service Bus namespaces and topics. This flavor is specifically designed for the Azure cloud platform, enabling teams to deploy reliable messaging infrastructure that supports decoupled communication between distributed applications. It facilitates event-driven architectures by managing topics and subscriptions with configurable capacity and SKU options.

This flavor helps automate the creation and lifecycle management of Azure Service Bus resources, improving operational efficiency and consistency across environments.

## Configurability

The schema exposes the following configurable properties under the `spec` section:

### size

- **Type:** `object`
- **Description:**  
  Defines the SKU and capacity of the Azure Service Bus namespace.
- **Properties:**
  - `sku`: String representing the Service Bus SKU (e.g., Basic, Standard, Premium).
  - `capacity`: String indicating the capacity units for the namespace (relevant for certain SKUs like Premium).

### topics

- **Type:** `object`
- **Description:**  
  Defines the set of Service Bus topics to be created within the namespace.
- **Structure:**
  - Each key is an arbitrary identifier for a topic configuration.
  - Each topic configuration contains:
    - `name`: The actual name of the topic to be created.
    - `status`: The operational status of the topic, typically set to `Active` or other states supported by Azure Service Bus.

Topics provide a mechanism for publishers to send messages and subscribers to receive messages in a scalable and decoupled manner.

### disabled

- **Type:** `boolean`
- **Description:**  
  Allows disabling the Service Bus resource provisioning without removing the configuration. Useful for temporarily suspending deployment or testing.

## Usage

This flavor is ideal for teams deploying Azure Service Bus namespaces with specific capacity and SKU requirements. Define topics to support messaging patterns such as publish/subscribe or event-driven workflows. Use the `size` block to optimize resource allocation according to workload demands. The ability to enable or disable resource provisioning provides flexibility during development and maintenance phases.

Azure Service Bus topics configured here can be integrated with other Azure services or external applications, providing a reliable backbone for asynchronous communication and event processing.
