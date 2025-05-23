# AWS Secret Manager – Default Flavor (v0.1)

## Overview

The `aws_secret_manager - default` flavor (v0.1) enables the creation and management of secrets in AWS Secret Manager. This module provides configuration options for defining the characteristics and behavior of the secrets.

Supported platforms:
- AWS

## Configurability

### Spec

#### `override_default_name` (`boolean`)

Set it to true if the secret is to be created with a custom name.

- **Title**: Override Default Name
- **Description**: Set it to true if the secret is to be created with a custom name

#### `override_name` (`string`)

Custom name for the secret. Applies only if `override_default_name` is set to true.

- **Title**: Override Name
- **Description**: Custom name for the secret. Applies only if `override_default_name` is set to true
- **Pattern**: '^[a-zA-Z0-9/_+=.@-]+$'
- **UI Placeholder**: "Enter the custom name"
- **UI Error Message**: "Value doesn't match the format eg. facets-secret"

#### `secrets` (`object`)

Enter a valid key-value pair for secrets in YAML format.

- **Title**: Secrets
- **Description**: "Enter a valid key-value pair for secrets in YAML format. Eg. key: value (provide a space after ':' as expected in the YAML format)"
- **UI YAML Editor**: true
- **UI Placeholder**: "Enter the value of the secret. Eg. key1: value1"

---

## Usage

Use this module to create and manage secrets in AWS Secret Manager. It is especially useful for:

- Storing sensitive information securely
- Managing access to secrets
- Enhancing the security and reliability of applications
