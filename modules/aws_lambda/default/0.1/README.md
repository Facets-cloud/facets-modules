# AWS Lambda Module

## Overview

The `aws_lambda - default` flavor (v0.1) enables the creation and management of AWS Lambda functions. This module provides configuration options for defining the characteristics and behavior of Lambda functions.

Supported clouds:
- AWS

## Configurability

- **Description**: Description of your Lambda Function.
- **Handler**: Lambda Function entrypoint in your code.
- **Runtime**: Lambda Function runtime includes the programming language, libraries, and execution settings required to run your function.
- **Release**: The release object containing either s3_path, image or build (object).
- **Environment Variables**: A map that defines environment variables for the Lambda Function.

## Usage

Use this module to create and manage AWS Lambda functions. It is especially useful for:

- Defining the characteristics and behavior of Lambda functions
- Managing the deployment and execution environment of Lambda functions
- Enhancing the functionality and integration of AWS applications
