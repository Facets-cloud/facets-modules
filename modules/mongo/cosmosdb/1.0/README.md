# Azure CosmosDB MongoDB Module

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/facets/modules)
[![Intent](https://img.shields.io/badge/intent-mongo-green.svg)](https://github.com/facets/modules)
[![Flavor](https://img.shields.io/badge/flavor-cosmosdb-orange.svg)](https://github.com/facets/modules)

## Overview

This Facets module creates and manages Azure Cosmos DB accounts configured with MongoDB API. It provides comprehensive configuration options for high availability, security, networking, and monitoring while maintaining MongoDB compatibility and global distribution capabilities.

The module supports both single-region and multi-region deployments with automatic failover, configurable consistency levels, and advanced features like analytical storage and private networking.

## Environment as Dimension

This module is designed to be environment-aware and creates unique resource names per environment using the Facets utility naming module. The CosmosDB account name is automatically generated based on the instance name and environment context to ensure global uniqueness across Azure regions.

Key environment-specific configurations include:
- **Account naming**: Uses Facets utility module with 44-character limit for global uniqueness
- **Resource tagging**: Automatically applies environment tags for governance
- **Location inheritance**: Uses location from the network details resource group
- **Networking**: Environment-specific virtual network and subnet configurations

## Resources Created

- **Azure Cosmos DB Account** - MongoDB-compatible database service with global distribution
- **MongoDB Databases** (optional) - One or more databases with configurable throughput settings
- **MongoDB Collections** (optional) - Collections within databases with shard keys and TTL settings
- **Private Endpoint** (optional) - Secure network connectivity for database access
- **Diagnostic Settings** (optional) - Monitoring and logging configuration for operational insights
- **Virtual Network Rules** (optional) - Network access control from specific subnets
- **Identity Configuration** (optional) - System or user-assigned managed identities

## Module Outputs

### Attributes (Technical Details)
The module exposes comprehensive technical information including:
- **Account Details**: Resource ID, endpoint, location, name, kind
- **Security Keys**: Primary/secondary keys and readonly keys
- **Networking**: Read/write endpoints, geo-locations
- **Configuration**: Consistency policy, capabilities, backup policy
- **Infrastructure**: Resource group name, private endpoint details
- **Database/Collection Info**: Names, IDs, throughput settings (if created)

### Interfaces (Consumer-Facing)
Essential connection details for consuming applications:
- **Primary Endpoint**: Main CosmosDB connection URL
- **Connection String**: MongoDB connection string for applications
- **Authentication Keys**: Primary and secondary access keys

## Key Features

### High Availability & Distribution
- Automatic failover with configurable geographic regions
- Multi-region write capabilities for global applications
- Configurable consistency levels (Strong, Session, Eventual, etc.)
- Zone-redundant storage options for backup

### Security & Compliance
- Customer-managed encryption keys via Azure Key Vault
- Private endpoint connectivity for network isolation
- IP-based firewall rules and virtual network integration
- System and user-assigned managed identities
- Comprehensive audit logging and monitoring

### Performance & Scalability
- Autoscale and standard throughput provisioning options
- Database-level and collection-level throughput configuration
- MongoDB server version selection (3.2 through 7.0)
- Analytical storage for real-time analytics workloads

### MongoDB Compatibility
- Native MongoDB API with aggregation pipeline support
- Document-level time-to-live (TTL) capabilities
- Custom indexing strategies for optimal query performance
- Shard key configuration for horizontal scaling

### Operational Excellence
- Comprehensive diagnostic logging to multiple targets
- Configurable backup policies (periodic or continuous)
- Point-in-time restore capabilities
- Resource tagging for cost management and governance

## Database and Collection Management

The module creates a single physical Azure CosmosDB instance that can host multiple logical MongoDB databases. Each database can contain multiple collections with individual configuration:

- **Shared Infrastructure**: All databases share the same compute, networking, and security settings
- **Logical Separation**: Data is isolated by database namespace
- **Throughput Sharing**: All databases share the configured RU/s pool
- **Individual Collection Settings**: Each collection can have unique shard keys and TTL settings

## Backup & Recovery

The module supports two backup strategies:

**Periodic Backup**: Traditional scheduled backups with configurable intervals (60-1440 minutes) and retention periods (8-87600 hours). Supports geo-redundant, locally-redundant, or zone-redundant storage.

**Continuous Backup**: Point-in-time restore capability with 7-day or 30-day retention tiers. Enables restoration to any point within the retention window.

## Security Considerations

When using this module in production environments, consider the following security practices:

- Enable private endpoints for network isolation when connecting from Azure virtual networks
- Configure customer-managed keys for encryption at rest using Azure Key Vault
- Implement IP-based firewall rules to restrict access to known client addresses
- Use virtual network rules to limit access to specific subnets
- Enable diagnostic logging to monitor access patterns and potential security threats
- Rotate access keys regularly and use managed identities where possible for application authentication