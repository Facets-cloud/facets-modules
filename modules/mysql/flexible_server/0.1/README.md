# MySQL Flexible Server Flavor Documentation

## Overview

The `mysql - flexible_server` flavor defines a managed MySQL database configuration using Azure Database for MySQL Flexible Server. This flavor is versioned `0.1` and integrates with the Facets infrastructure, offering a customizable and cost-efficient MySQL environment within Azure's cloud ecosystem.

## Configurability

This flavor offers the following configurable parameters:

- **MySQL Version**:  
  Supported versions include `5.7` and `8.0.21`, ensuring compatibility with a wide range of applications.  
  Current configuration: `8.0.21`

- **Size Configuration**:
  - **Writer Node**:
    - Instance type: `GP_Standard_D2ds_v4`
  - **Reader Node**:
    - Instance type: `GP_Standard_D2ds_v4`
    - Instance count: `0`

- **Metadata**:
  - Tags and ownership can be specified under the `metadata` section.
  - The system is managed via the `facets` platform, ensuring consistency and governance.

- **Cloud Provider**:  
  Azure is the supported cloud provider, indicated by the `clouds` section.

- **Schema Reference**:  
  Based on the schema located at:  
  `https://facets-cloud.github.io/facets-schemas/schemas/mysql/mysql.schema.json`

## Usage

This flavor is suitable for deployments requiring:

- Fully managed MySQL in Azure with high availability options
- Flexible instance configurations to suit various performance requirements
- Scalability via multiple reader instances
- Seamless integration into infrastructure-as-code workflows and Azure-native services
