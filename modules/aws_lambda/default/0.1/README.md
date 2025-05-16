# AWS Lambda – Default Flavor (v0.1)

## Overview

The `aws_lambda - default` flavor (v0.1) enables the creation and management of AWS Lambda functions. This module provides configuration options for defining the characteristics and behavior of the Lambda functions.

Supported platforms:
- AWS

## Configurability

### Spec

#### `description` (`string`)

Description of your Lambda Function.

- **Title**: Description
- **Description**: Description of your Lambda Function
- **UI Placeholder**: "Enter description of lambda functions"

#### `handler` (`string`)

Lambda Function entrypoint in your code.

- **Title**: Handler
- **Description**: Lambda Function entrypoint in your code
- **UI Placeholder**: "Enter handler for the lambda Eg. main.lambda_handler"

#### `runtime` (`string`)

Lambda Function runtime.

- **Title**: Runtime
- **Description**: Lambda Function runtime
- **Default**: None
- **UI No Sort**: true
- **Enum**:
  - "nodejs22.x"
  - "nodejs20.x"
  - "nodejs18.x"
  - "python3.13"
  - "python3.12"
  - "python3.11"
  - "python3.10"
  - "python3.9"
  - "java21"
  - "java17"
  - "java11"
  - "java8.al2"
  - "dotnet8"
  - "ruby3.3"
  - "ruby3.2"
  - "provided.al2023"
  - "provided.al2"
- **Example**: "python3.8"

#### `release` (`object`)

The release object containing either `s3_path`, `image`, or `build` (object).

- **Title**: Release
- **Description**: The release object containing either `s3_path`, `image`, or `build` (object)
- **Default**: None
- **Properties**:
  - **s3_path** (`string`): The full path of the zip file present in S3.
    - **Title**: S3 Path
    - **Description**: The full path of the zip file present in S3
    - **UI Placeholder**: "Enter S3 path for your lambda application. Eg lambda-facets/lambda.zip"

#### `env` (`object`)

A map that defines environment variables for the Lambda Function.

- **Title**: Environment Variables
- **Description**: A map that defines environment variables for the Lambda Function
- **UI YAML Editor**: true
- **UI Placeholder**: "Enter the value of the env variable. Eg. key: value"

---

## Usage

Use this module to create and manage AWS Lambda functions. It is especially useful for:

- Defining the characteristics and behavior of Lambda functions
- Managing the deployment and runtime environment of Lambda functions
- Enhancing the performance and reliability of serverless applications
