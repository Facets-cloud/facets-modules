# DynamoDB - Default Flavor (v0.2)

## Overview

This document describes the configuration and usage of a DynamoDB resource defined using the default flavor in version 0.2 of the schema. DynamoDB is a managed NoSQL database service provided by AWS, designed for high availability, low latency, and scalability. It is used in scenarios that require fast and predictable performance at scale.

The configuration targets key-value access patterns, where data is accessed based on a single primary key known as the partition key. This flavor is suited for simple use cases and has been streamlined for quick provisioning with minimal setup, making it ideal for feature toggles, distributed locking, configuration management, or tracking lightweight metadata.

This resource is cloud-specific and supports only the AWS environment. Redundancy in the cloud list indicates multiple cloud deployment options within AWS regions or environments.

---

## Configurability

The configuration is structured around a standardized schema that ensures consistent behavior across different deployments. The schema defines the shape, behavior, and metadata of the DynamoDB resource. Below is an in-depth explanation of each part of the configuration:

### Schema Declaration

The schema version is referenced at the beginning, indicating that this configuration complies with a specific version of a publicly available schema definition. This allows validation tools and automation systems to parse, interpret, and verify the configuration against defined rules.

### Resource Kind

The kind specifies the type of resource being created, which in this case is a DynamoDB table. This ensures that infrastructure orchestration systems like Facets recognize it as a database resource and treat it accordingly during provisioning and management cycles.

### Flavor

### Disabled Flag

The disabled field allows the resource to be defined in the configuration without actually provisioning it. This is particularly useful during development, testing, or phased rollouts, where the presence of a resource in the configuration repository is needed, but its live deployment is to be controlled or deferred.

### Metadata Block

The metadata section is a placeholder for annotations, tags, or any additional information that might be required by downstream systems or team conventions. In this configuration, it is empty, but it can be extended to support descriptions, cost center tagging, ownership metadata, or environment-specific notes.

### Specification Section

This is the most critical part of the configuration, where the behavior of the DynamoDB table is fully defined.

#### Attributes

The attributes define the structure of the table's keys. In this configuration, a single attribute is declared. It includes:

- A logical identifier used within the schema (not necessarily the same as the attribute's name in DynamoDB).
- The actual name of the attribute as it appears in the table.
- The data type, where supported types include string, number, and binary.

This attribute is intended to be used as the partition key, enabling fast, hashed access to individual records.

#### Hash Key

The hash key (also known as the partition key) is a required element that determines how data is distributed across the internal partitions of the DynamoDB system. Every item written to the table must have a unique value for this key. The hash key plays a critical role in ensuring data scalability and even load distribution.

There is no sort key defined in this flavor, which means that the table does not support composite keys or grouped sorting of records under a common partition key. This simplifies the data model and reduces complexity, but also limits access patterns to simple key lookups.

---

## Usage

This configuration is best suited for systems that require:

- Reliable and fast key-based retrieval of individual records.
- Simplified configuration without the need for complex index management.
- Minimal overhead during setup and deployment.
- Integration with applications that rely on distributed state or session management.

Common use cases include:

- **Distributed locking systems**, where each lock is identified by a unique key, and the state is stored in a consistent location.
- **Feature flag or configuration storage**, where settings are retrieved based on environment or component identifiers.
- **User metadata indexing**, where fast lookup of profile or state information is needed using a unique identifier.

The configuration is intended to be deployed as part of a declarative infrastructure provisioning process. It allows teams to maintain resource definitions in version control, apply automated validations, and manage deployments using a consistent and reliable framework.

