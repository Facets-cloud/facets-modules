# AWS SNS - Default Flavor

## Overview

The `sns` intent with the `default` flavor provides a declarative approach to managing Amazon Simple Notification Service (SNS) resources on AWS. This flavor enables secure, scalable event-driven communication by allowing topic creation, subscription management, and event triggers within cloud-native and Kubernetes environments. It supports fine-grained control over encryption, subscription protocols, and event sources, streamlining integration with other AWS services such as SQS and S3.

## Configurability

The configuration under the `spec` section allows detailed customization of SNS topics, subscriptions, and triggers. Key configurable properties include:

### disable_encryption

- **Type:** `boolean`
- **Default:** `false`
- **Description:**  
  Controls whether server-side encryption (SSE) is enabled on the SNS topic. By default, encryption is enabled using AWS-managed SNS keys to protect message data at rest. Setting this flag to `true` disables SSE, which may be necessary in specific scenarios but generally not recommended for production use.

### subscriptions

- **Type:** `object`
- **Description:** Defines the SNS subscriptions to other AWS resources, primarily supporting SQS endpoints.
- **Structure:**
  - Multiple named subscription blocks can be defined under this key.
  - Each subscription must specify:
    - `protocol`: Must be set to `"sqs"` for SQS subscriptions.
    - `endpoint`: The ARN or URL endpoint of the subscribing AWS resource (e.g., an SQS queue ARN).
    - `raw_message_delivery`: Optional boolean to enable raw message delivery, which disables JSON formatting for the messages sent to the endpoint. Defaults to `false`.

### triggers

- **Type:** `object`
- **Description:** Configures event sources that can publish messages to the SNS topic automatically.
- **Example: S3 Event Notification**
  - `name`: Name of the S3 bucket generating events.
  - `arn`: ARN of the S3 bucket.
  - `events`: A list of S3 event types to subscribe to (e.g., `s3:ObjectCreated:*`).
  - `filter_prefix`: Optional prefix filter to limit event notifications to objects with specific key prefixes.
  - `filter_suffix`: Optional suffix filter for object keys.

### Disabled Flag

- **disabled**: Boolean flag at the root level to disable the entire SNS resource provisioning without deleting the configuration, useful for staging or temporary suspension.

This flexible structure supports complex event-driven architectures by linking SNS topics with multiple subscribers and triggering events from other AWS services.

## Usage

This flavor is ideal for implementing scalable pub/sub messaging within AWS environments. It supports secure communication via encrypted topics and multiple subscription endpoints such as SQS queues. It is useful for integrating event notifications from services like S3 into messaging workflows. The configuration enables automation of topic creation, subscription binding, and event triggers, simplifying operational overhead while maintaining robust security and delivery guarantees.
