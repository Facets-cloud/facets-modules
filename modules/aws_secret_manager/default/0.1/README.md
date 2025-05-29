# AWS Secret Manager Module

## Overview

The `aws_secret_manager - default` flavor (v0.1) enables the creation and management of secrets using AWS Secret Manager. This module provides configuration options for defining the characteristics and behavior of secrets.

Supported clouds:
- AWS

## Configurability

- **Override Default Name**: Set it to true if the secret is to be created with a custom name.
- **Override Name**: Custom name for the secret. Applies only if `override_default_name` is set to true.
- **Secrets**: Enter a valid key-value pair for secrets in YAML format.

## Usage

Use this module to create and manage secrets using AWS Secret Manager. It is especially useful for:

- Defining the characteristics and behavior of secrets
- Managing sensitive information securely
- Enhancing the security and functionality of AWS applications
