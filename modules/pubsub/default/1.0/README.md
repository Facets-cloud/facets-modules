# Google Cloud Pub/Sub Module

A fully-managed real-time messaging service for Google Cloud that enables message exchange between independent applications with native support for AWS Kinesis Data Streams ingestion.

## Module Architecture

This module follows a **modular file architecture** for better maintainability and separation of concerns:

### Core Files Structure

- **`main.tf`**: Shared locals and common configuration used across all resources
- **`topic.tf`**: Pub/Sub topic resource with Kinesis ingestion support and topic-specific locals
- **`schema.tf`**: Schema resource and schema-related configuration locals
- **`pull_subscriptions.tf`**: Pull subscription resources and related transformation logic
- **`push_subscriptions.tf`**: Push subscription resources and related transformation logic
- **`variables.tf`**: All input variables and comprehensive validation rules
- **`outputs.tf`**: Module outputs with resource references

### Benefits of This Architecture

- **Separation of Concerns**: Each file handles a specific logical component
- **Maintainability**: Easy to locate and modify specific functionality
- **Readability**: Cleaner, focused code with relevant locals co-located with resources
- **Modularity**: Each component can be understood and modified independently

## Overview

This module provides a comprehensive, native Terraform implementation for Google Cloud Pub/Sub without relying on external modules. It supports advanced features including Kinesis ingestion, schema validation, and sophisticated subscription management with dead letter policies and retry mechanisms.

## Environment as Dimension

This module is environment-aware and automatically appends the environment's cluster code to resource names:
- **Topic names**: `{instance_name}-{cluster_code}`
- **Schema names**: `{schema_name}-{cluster_code}` (when schema validation is enabled)
- **Subscription names**: `{subscription_name}-{cluster_code}`

This ensures resource isolation across different environments while maintaining consistent naming patterns.

## Resources Created

This module creates the following Google Cloud resources:

- **Pub/Sub Topic**: Primary message topic with configurable retention, encryption, and optional Kinesis ingestion
- **Pub/Sub Schema** (optional): Message validation schema supporting AVRO and Protocol Buffer formats
- **Pull Subscriptions** (optional): Server-initiated message consumption with configurable acknowledgment policies
- **Push Subscriptions** (optional): Pub/Sub-initiated message delivery to HTTP endpoints with OIDC authentication
- **Dead Letter Policies** (per subscription): Automatic handling of undeliverable messages
- **Retry Policies** (per subscription): Configurable exponential backoff strategies for failed deliveries

## Key Features

### AWS Kinesis Data Streams Integration
- **Import Topics**: Direct ingestion from Amazon Kinesis Data Streams into Pub/Sub
- **Cross-cloud streaming**: Seamlessly stream data from AWS to Google Cloud
- **Federated authentication**: Secure access using workload identity federation
- **Real-time ingestion**: Continuous data flow with automatic scaling

### Schema Validation
- **AVRO** and **Protocol Buffer** schema types
- **JSON** and **Binary** encoding options
- **Optional validation**: Enable/disable schema validation per topic
- **Environment-aware naming**: Schema names include cluster code for isolation

### Advanced Subscription Management
- **Pull Subscriptions**: Client pulls messages from Pub/Sub
- **Push Subscriptions**: Pub/Sub pushes messages to HTTP endpoints
- **Conditional features**: Enable/disable dead letter policies, retry policies, and OIDC authentication
- **Message ordering** and **exactly-once delivery** guarantees

### Enhanced User Experience
- **Toggle-based configuration**: Collapsible sections in the UI for better organization
- **Conditional visibility**: Fields appear only when their parent feature is enabled
- **Comprehensive validation**: Input validation with helpful error messages

## Security Considerations

When using this module, consider the following security aspects:

- **Message Encryption**: Configure KMS keys for topic-level encryption to protect sensitive message content
- **Access Control**: Implement proper IAM roles and permissions for Pub/Sub resources
- **Push Endpoint Security**: Ensure push endpoints use HTTPS and implement proper authentication
- **OIDC Tokens**: Use service accounts with minimal required permissions for OIDC token generation

### Kinesis Ingestion Security Setup

When enabling Kinesis ingestion, additional security configuration is required:

1. **AWS IAM Role**: Create an AWS IAM role with permissions to read from Kinesis Data Streams
2. **Workload Identity Federation**: Configure federated identity between GCP and AWS
3. **GCP Service Account**: Create a GCP service account for cross-cloud authentication
4. **Cross-cloud Permissions**: Ensure proper permissions in both AWS and GCP

Required AWS IAM policy for the role:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:ListShards",
        "kinesis:SubscribeToShard"
      ],
      "Resource": "arn:aws:kinesis:*:*:stream/*"
    }
  ]
}
```

## Configuration Examples

### Basic Topic Only
```yaml
spec:
  topic_message_retention_duration: "86400s"
```

### Topic with Schema Validation
```yaml
spec:
  schema:
    enabled: true
    name: "user-events"
    type: "AVRO"
    encoding: "JSON"
    definition: |
      {
        "type": "record",
        "name": "UserEvent",
        "fields": [
          {"name": "userId", "type": "string"},
          {"name": "eventType", "type": "string"},
          {"name": "timestamp", "type": "long"}
        ]
      }
```

### Topic with Kinesis Ingestion
```yaml
spec:
  kinesis_ingestion:
    enabled: true
    stream_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-kinesis-stream"
    consumer_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-kinesis-stream/consumer/my-consumer:1234567890"
    aws_role_arn: "arn:aws:iam::123456789012:role/pubsub-kinesis-role"
    gcp_service_account: "pubsub-kinesis@my-project.iam.gserviceaccount.com"
```

### Advanced Subscription Configuration
```yaml
spec:
  pull_subscriptions:
    analytics-pull:
      ack_deadline_seconds: 30
      enable_exactly_once_delivery: true
      dead_letter_policy:
        enabled: true
        dead_letter_topic: "failed-messages"
        max_delivery_attempts: 5
      retry_policy:
        enabled: true
        minimum_backoff: "10s"
        maximum_backoff: "600s"
  
  push_subscriptions:
    webhook-push:
      push_endpoint: "https://api.example.com/webhook"
      oidc_token:
        enabled: true
        service_account_email: "push-service@project.iam.gserviceaccount.com"
        audience: "https://api.example.com"
      dead_letter_policy:
        enabled: true
        dead_letter_topic: "webhook-failures"
        max_delivery_attempts: 3
```

## Breaking Changes from Previous Version

This version represents a complete rewrite with several breaking changes:

1. **Native Implementation**: No longer uses the external `terraform-google-modules/pubsub/google` module
2. **Schema Configuration**: Now requires `enabled: true` to activate schema validation
3. **Conditional Policies**: Dead letter and retry policies require explicit `enabled: true`
4. **OIDC Structure**: Push subscription OIDC configuration moved from `push_config.oidc_token` to `oidc_token`
5. **Enhanced Validation**: More comprehensive input validation with detailed error messages

## Module Outputs

- **id**: The Pub/Sub topic ID
- **name**: The topic name
- **project_id**: The GCP project ID
- **kinesis_ingestion_enabled**: Boolean indicating if Kinesis ingestion is active
- **schema_enabled**: Boolean indicating if schema validation is active
- **schema_name**: The schema name (if enabled)
- **pull_subscription_names**: Map of pull subscription names
- **push_subscription_names**: Map of push subscription names

## Prerequisites

- Google Cloud Project with Pub/Sub API enabled
- Appropriate IAM permissions for Pub/Sub resources
- For Kinesis ingestion: AWS account with proper IAM setup and workload identity federation configured
