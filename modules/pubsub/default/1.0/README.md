# Google Cloud Pub/Sub Module

![Version](https://img.shields.io/badge/version-1.0-blue)
![Cloud](https://img.shields.io/badge/cloud-GCP-blue)

## Overview

This module creates a fully-managed Google Cloud Pub/Sub topic with subscriptions for real-time messaging between independent applications. It provides a clean, standalone implementation focused purely on Pub/Sub functionality without external dependencies.

## Environment as Dimension

The module is environment-aware through the `var.environment` parameter, which affects:

- **Resource naming**: All resources include the environment cluster code suffix for uniqueness across environments
- **Labeling**: Resources are automatically tagged with the environment name
- **Project targeting**: Resources are deployed to the specified GCP project per environment

Different environments may have varying configurations for message retention, subscription settings, and security policies while maintaining consistent resource naming patterns.

## Resources Created

This module creates the following Google Cloud resources:

- **Pub/Sub Topic** - The main message topic with configurable retention and optional KMS encryption
- **Pub/Sub Schema** - Optional message validation schema supporting AVRO and Protocol Buffer formats
- **Pull Subscriptions** - Client-pull based subscriptions with configurable acknowledgment settings
- **Push Subscriptions** - HTTP endpoint push subscriptions with retry and dead letter policies
- **Dead Letter Topics** - Automatic handling of failed message delivery (when configured)

## Security Considerations

- **Project Isolation**: All resources are created within the specified GCP project boundary
- **KMS Encryption**: Optional Cloud KMS encryption for messages at rest when `topic_kms_key_name` is provided
- **IAM Permissions**: Module requires appropriate Pub/Sub permissions in the target project
- **Network Security**: Push endpoints should implement proper authentication and validation
- **Message Filtering**: Optional message filters can be applied to subscriptions for content-based routing

All resources inherit standard security labels for compliance tracking and are created with Google Cloud's default security posture.