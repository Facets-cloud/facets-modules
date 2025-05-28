# AWS Event Bus Module

## Overview

This module provisions a **AWS EventBridge Event Bus**, allowing you to create isolated event buses for use with event-driven architectures. Custom event buses enable you to decouple applications by routing events between services or microservices in a scalable and organized way.

This module is supported only on **AWS**.

---

## Configurability

The following parameter can be configured under the `spec` block:

**`metadata`**

- `metadata`: 
  Contains resource-level metadata such as a user-defined name or description.

**`spec`**

- **`name`**:
  The name of the custom AWS EventBridge event bus to be created.

  - Must be **unique** within the AWS account and region.
  - Can contain **alphanumeric characters**, **hyphens (`-`)**, and **underscores (`_`)**.

## Usage
When you define this module with the required name field:

- A **custom EventBridge event bus** will be created in your AWS account.
- This event bus acts as an isolated channel for your applications to publish and subscribe to events.
- The bus can then be:
  - Targeted by EventBridge rules from other services or microservices.
  - Used for routing events to AWS targets like Lambda, SQS, SNS, Step Functions, etc.
  - Referenced by other modules such as `aws_eventbridge_rule` to define event patterns and destinations.

