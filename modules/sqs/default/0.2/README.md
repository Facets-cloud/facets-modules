# AWS SQS - Default Flavor

## Overview

The `sqs` intent with the `default` flavor provides a declarative way to manage Amazon Simple Queue Service (SQS) resources within AWS environments. This flavor focuses on configuring SQS queues with optional server-side encryption (SSE) support to enhance security. It simplifies integrating reliable messaging and decoupling components in cloud-native applications by automating the provisioning and configuration of SQS queues.

## Configurability

The configuration is defined under the `spec` section with a focus on encryption options and queue management. The key configurable property includes:

### use_sqs_managed_sse

- **Type:** `boolean`
- **Default:** `false`
- **Description:**  
  When enabled (`true`), this option configures the SQS queue to use AWS-managed server-side encryption (SSE) for data at rest. This feature uses AWS’s own encryption keys to automatically encrypt messages in the queue, simplifying compliance and security management.  
  If this flag is set to `true`, it takes precedence over specifying any customer-managed key ID (CMK), ensuring that the queue is encrypted using AWS-managed keys without the need for manual key management.

Additional queue configurations such as message retention period, visibility timeout, and delivery delay can be integrated with this flavor in extended versions, but the current version focuses primarily on managing encryption settings.

### Disabled Flag

- **disabled**: This root-level boolean flag allows users to disable the provisioning of the SQS queue resource entirely without removing the configuration. Setting this to `true` can be useful for temporary suspension or staged deployments.

This simple yet secure configurability allows users to leverage AWS SQS with encryption best practices easily integrated into their infrastructure as code workflows.

## Usage

This flavor is intended for teams looking to automate SQS queue provisioning with a focus on encryption and secure message handling in AWS. It is ideal for building event-driven architectures, decoupling microservices, or implementing reliable message queuing in cloud applications. By enabling AWS-managed SSE, it helps meet security requirements while reducing operational overhead of managing encryption keys manually.
