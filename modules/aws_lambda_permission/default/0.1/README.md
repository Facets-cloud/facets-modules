# AWS Lambda Permission – Default Flavor (v0.1)

## Overview

The `aws_lambda_permission - default` flavor (v0.1) enables the creation and management of permissions for AWS Lambda functions. This module provides configuration options for defining the characteristics and behavior of the Lambda permissions.

Supported platforms:
- AWS

## Configurability

### Spec

#### `allowed_triggers` (object)

Defines the allowed triggers for the Lambda function.

- **allowedVPC** (`object`)  
  Configuration for VPC triggers.

#### `lambda_name` (`string`)

The name of the Lambda function.

- **Title**: Lambda Name
- **Description**: The name of the Lambda function

#### `lambda_version` (`string`)

The version of the Lambda function.

- **Title**: Lambda Version
- **Description**: The version of the Lambda function

---

## Usage

Use this module to create and manage permissions for AWS Lambda functions. It is especially useful for:

- Defining the characteristics and behavior of Lambda permissions
- Managing access and triggers for Lambda functions
- Enhancing the security and functionality of serverless applications
