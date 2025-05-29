# AWS VPC Module

## Overview

This module manages AWS VPC network configurations. It supports creating new VPCs or using existing VPCs, with options for multi-Availability Zone (AZ) deployment and custom CIDR blocks. Designed for AWS cloud environments.

## Conf

- **choose_vpc_type** (radio)  
  Choose whether to create a new VPC or use an existing VPC.  
  Options:  
  - Create New VPC (default)  
  - Use Existing VPC  

- **azs** (array)  
  List of Availability Zones where the VPC or network components will be deployed. Example: `us-east-1a`, `us-east-1b`.  

- **vpc_cidr** (string)  
  CIDR block for the VPC. Must be a valid private IP range in CIDR notation, e.g., `10.45.0.0/16`. Validation is applied to ensure correctness.

- **enable_multi_az** (boolean)  
  Enable deployment across multiple Availability Zones for high availability.

- **existing_vpc_id** (string)  
  When using an existing VPC, specify the VPC ID to deploy network components within it. Only visible if "Use Existing VPC" is selected.

## Usage

Use this module to configure AWS network infrastructure flexibly, either by creating a new VPC with specified CIDR and AZs or integrating with an existing VPC for resource deployment. Supports multi-AZ setups to improve resilience and availability.
