# Google Cloud Storage Bucket Module

## Overview

This module creates and manages a Google Cloud Storage (GCS) bucket with configurable options. It supports customization of location, storage class, versioning, lifecycle rules, and access controls. It also provides predefined IAM roles and an IAM condition for access management.

## Environment as Dimension

The module creates a GCS bucket with a name that includes the environment's unique name to ensure uniqueness across environments. It applies environment-specific tags automatically to the bucket. The bucket location will default to the environment's region when no specific location is provided, with location overrides available on a per-environment basis.

## Resources Created

- Google Cloud Storage bucket with configurable attributes:
  - Location (defaults to environment's region if not specified, can be overridden per environment)
  - Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)
  - Object versioning
  - Lifecycle rules for object management
  - Uniform bucket-level access control
  - Custom labels (fully customizable via YAML editor)

## Security Considerations

- Uniform bucket-level access is enabled by default to enforce consistent access control
- The module provides predefined IAM roles for read-only (`roles/storage.objectViewer`) and read-write (`roles/storage.objectAdmin`) access
- IAM condition title and expression using `resource.name.startsWith()` are provided to target this specific bucket in IAM policies
- Sensitive operations like permanent deletion are protected by lifecycle preconditions

## Features

- Advanced name generation with built-in length limiting functionality
  - Ensures bucket names are within the GCS 63-character length limit
  - Falls back to truncation with random suffix for very long names
  - Automatically handles GCS naming constraints (lowercase letters, numbers, hyphens)
- Regional fallback ensures the bucket is always created in an appropriate location by using environment.region when no specific location is provided
- Flexible labeling system allows users to define any custom labels they need via YAML editor
