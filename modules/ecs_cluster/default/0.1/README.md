# AWS ECS Cluster Module – Detailed Explanation

## Overview
The AWS ECS Cluster module is designed to simplify the creation and management of ECS clusters on AWS. ECS (Elastic Container Service) is a fully managed container orchestration service that helps you deploy, manage, and scale containerized applications easily.

This module allows users to define the lifecycle type of their ECS cluster, enabling them to choose the cost and availability model that best suits their workload.

## Configurability

### Cluster Specification
The key configurable property for this module is the **cluster specification**, which includes:

- **Lifecycle**: This property determines the type of instances the ECS cluster will use.

  - **Spot Instances**: Choosing the "spot" lifecycle means the ECS cluster will use AWS Spot Instances. Spot Instances allow you to take advantage of unused EC2 capacity at a significantly reduced cost. However, these instances can be interrupted by AWS with short notice if the capacity is needed elsewhere. This option is ideal for flexible, fault-tolerant workloads that can handle interruptions.

  - **On-Demand Instances**: Selecting "ondemand" means the ECS cluster will be composed of on-demand instances. These instances provide higher availability and reliability since they are not subject to interruption. This option is best suited for critical workloads that require consistent uptime.

## Usage
When using this module, you configure the ECS cluster by setting the lifecycle option according to your desired instance type and cost model.

- If cost optimization is your priority and your workloads can tolerate interruptions, set the lifecycle to **spot**.

- If reliability and availability are more important, choose **ondemand** to run your cluster on standard on-demand EC2 instances.

By abstracting this setting into a single property, the module streamlines cluster creation and ensures clear intent about the underlying infrastructure behavior.

The module also provides outputs that reference the created ECS cluster resources, allowing integration with other infrastructure components or further automation workflows.


