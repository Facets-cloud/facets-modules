# Azure VPC Flavor

## Overview

This module manages network configurations for Azure Virtual Networks (VNet), providing options to create a new VNet or use an existing one. It supports configuring availability zones and CIDR blocks within Azure cloud environments.

## Configurability

- **choose_vpc_type** (radio)  
  Select whether to create a new VNet or use an existing VNet.  
  Options:  
  - Create New VPC (default)  
  - Use Existing VPC  

- **azs** (array)  
  List of Availability Zones for the VNet deployment, e.g., `1`, `2`.

- **vpc_cidr** (string)  
  CIDR block for the VNet. Must be a valid private IP range in CIDR notation. The CIDR block `10.0.0.0/16` is explicitly disallowed. Example: `10.45.0.0/16`. Validation is applied to ensure correctness.

- **vnet_name** (string)  
  Name of the existing VNet when using an existing network. This field is only visible if "Use Existing VPC" is selected.

- **resource_group_name** (string)  
  Azure Resource Group name where the existing VNet resides. Only visible when using an existing VPC.

## Usage

Use this module to configure Azure network infrastructure either by creating a new VNet with specified CIDR and availability zones or by integrating with an existing VNet and resource group. The module supports multi-AZ deployments to ensure high availability within Azure.
