# MySQL CloudSQL Flavor Documentation

## Overview

The `mysql - cloudsql` flavor defines a managed MySQL database configuration using Google Cloud SQL on GCP. This flavor is versioned `0.1` and integrates with the Facets infrastructure, providing a flexible and scalable MySQL environment managed via Google Cloud's SQL offering.

## Configurability

This flavor offers the following configurable parameters:

- **MySQL Version**:  
  Selectable versions include `8.0`, `5.7`, and `5.6`, allowing compatibility with various application requirements.  
  Current configuration: `8.0`

- **Size Configuration**:
  - **Writer Node**:
    - Instance type: `db-f1-micro`
    - Volume: `10G`
  - **Reader Node**:
    - Instance type: `db-f1-micro`
    - Volume: `10G`
    - Instance count: `0`

- **Metadata**:
  - Tags and ownership can be specified under the `metadata` section.
  - The system is managed via the `facets` platform, ensuring consistency and governance.

- **Cloud Provider**:  
  GCP is the supported cloud provider, indicated by the `clouds` section.

- **Schema Reference**:  
  Based on the schema located at:  
  `https://facets-cloud.github.io/facets-schemas/schemas/mysql/mysql.schema.json`

## Usage

This flavor is suitable for deployments requiring:

- Managed MySQL databases in GCP with high availability
- Compatibility with multiple MySQL engine versions
- Lightweight and cost-effective instances using predefined or custom machine types
- Flexible volume sizing for both reader and writer nodes
- Integration with infrastructure-as-code tools and cloud-native management (e.g., via Facets)
