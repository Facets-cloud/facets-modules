# MySQL Aurora Flavor Documentation

## Overview

The `mysql - aurora` flavor defines a managed MySQL database configuration built on Amazon Aurora, leveraging AWS's cloud-native capabilities for high availability and scalability. This flavor is versioned `0.1` and integrates with the Facets infrastructure, intended for environments where a robust, cloud-managed MySQL database is needed.

## Configurability

This flavor offers the following configurable parameters:

- **MySQL Version**:  
  Set to `8.0.mysql_aurora.3.02.0`, aligning with a specific Aurora MySQL engine version for compatibility and performance tuning.

- **Size Configuration**:
  - **Writer Node**:
    - Instance type: `db.t4g.medium`
    - Instance count: `1`
  - **Reader Node**:
    - Instance type: `db.t4g.medium`
    - Instance count: `1`

- **Metadata**:
  - Tags and ownership can be specified under the `metadata` section.
  - The system is managed via the `facets` platform, ensuring consistency and governance.

- **Cloud Provider**:  
  AWS is the supported cloud provider, indicated by the `clouds` section.

- **Schema Reference**:  
  Based on the schema located at:  
  `https://facets-cloud.github.io/facets-schemas/schemas/mysql/mysql.schema.json`

## Usage

This flavor is suitable for deployments requiring:

- High availability and failover support via Aurora’s distributed storage
- Performance benefits of Aurora with MySQL compatibility
- Lightweight and cost-effective instances using T4g-based resources
- Read scalability through separate reader instances
- Integration with infrastructure-as-code tools and cloud-native management (e.g., via Facets)
