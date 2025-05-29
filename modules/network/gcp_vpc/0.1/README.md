# GCP VPC Module

## Overview

This module manages Google Cloud Platform (GCP) Virtual Private Cloud (VPC) network configurations. It supports creating a new VPC, using an existing VPC, or configuring a Shared VPC, enabling flexible network setups for GCP environments.

## Configurability

- **choose_vpc_type**  
  Select the type of VPC to configure:  
  - Create New VPC
  - Use Existing VPC  
  - Shared VPC  

- **azs** (array)  
  List of availability zones for the VPC, e.g., `asia-southeast1-a`, `asia-southeast1-b`.

- **vpc_cidr** (string)  
  CIDR block for the VPC. Must be a valid private IP range in CIDR notation. Example: `10.45.0.0/16`. Validation is applied to ensure correctness.

- **vnet_name** (string)  
  Name of the existing VPC. Visible only when "Use Existing VPC" is selected.

### Shared VPC Specific Fields

These fields are visible and required only when the **Shared VPC** option is selected:

- **host_project_id**  
  Unique identifier for the host project's VPC.

- **host_project_pods_secondary_range_name**  
  Name of the secondary IP range for pods in the host project's VPC.

- **host_project_pods_secondary_ip_range**  
  CIDR block for the secondary IP range for pods.

- **host_project_services_secondary_range_name**  
  Name of the secondary IP range for services in the host project's VPC.

- **host_project_services_secondary_ip_range**  
  CIDR block for the secondary IP range for services.

- **host_project_allocatable_ip_range**  
  Range of IPs allocatable within the host project's VPC.

- **host_project_subnet_id**  
  Identifier for the host project's subnet.

- **host_project_subnet_name**  
  Name of the host project's subnet.

- **host_project_subnet_ip_range**  
  CIDR block for the subnet IP range.

- **host_project_vpc_id**  
  Project VPC ID.

- **host_project_vpc_name**  
  Name of the host project's VPC.

- **host_project_google_service_id**  
  Identifier for the Google service associated with the host project's VPC.

- **host_project_google_service_name**  
  Name of the Google service associated with the host project's VPC.

## Usage

Use this module to configure GCP networking tailored to different scenarios:

- **Create New VPC:** Define a new VPC with specified CIDR block and availability zones.
- **Use Existing VPC:** Reference an existing VPC by name.
- **Shared VPC:** Configure shared network resources using detailed host project and subnet information, enabling multiple projects to share a common VPC.

This flexibility allows deploying GCP resources with appropriate networking aligned to organizational standards and cloud architecture requirements.
