# AWS IAM Role – Default Flavor (v0.1)

## Overview

The `aws_iam_role - default` flavor (v0.1) enables the creation and management of AWS IAM roles. This module provides configuration options for defining the characteristics and behavior of the IAM roles.

Supported platforms:
- AWS

## Configurability

### Spec

#### `irsa` (`object`)

IRSA block which is required to attach EKS OIDC to service accounts for allowing applications to get cloud credentials.

- **Description**: IRSA block which is required to attach EKS OIDC to service accounts for allowing applications to get cloud credentials
- **Properties**:
  - **service_accounts** (`object`): The map of all service accounts that you want to attach IRSA.
    - **Title**: Service Accounts
    - **Description**: The map of all service accounts that you want to attach IRSA
    - **Pattern Properties**:
      - **type** (`object`): Service Account Name
        - **Title**: Service Account Name
        - **Key Pattern**: '^[a-zA-Z0-9_.-]*$'
        - **Description**: An arbitrary name given to the service account which is not used anywhere
        - **Properties**:
          - **name** (`string`): The name of the service account that you want to attach the role to with the trust relationship.
            - **Description**: The name of the service account that you want to attach the role to with the trust relationship
            - **Pattern**: '^(?!-)[a-zA-Z0-9]+(?:[_-][a-zA-Z0-9]+)*(?<!-)$'
            - **UI Error Message**: "Service account names must contain only letters, numbers, underscores and hyphens, cannot contain consecutive hyphens, and must not include spaces or special characters "
  - **oidc_providers** (`object`): The map of all OIDC ARNs that you want to attach IRSA.
    - **Title**: OIDC Providers
    - **Description**: The map of all OIDC ARNs that you want to attach IRSA
    - **Pattern Properties**:
      - **type** (`object`): OIDC Provider ARN
        - **Title**: OIDC Provider ARN
        - **Key Pattern**: '^[a-zA-Z0-9_.-]*$'
        - **Description**: An arbitrary name given to the OIDC provider which is not used anywhere
        - **Properties**:
          - **arn** (`string`): The ARN of the OIDC that you want to attach the role to with the trust relationship.
            - **Description**: The ARN of the OIDC that you want to attach the role to with the trust relationship
            - **Pattern**: '^arn:aws:iam::[0-9]{12}:oidc-provider\/[a-zA-Z0-9._\-\/]+$'
            - **UI Error Message**: "Invalid OIDC ARN format. Ensure it follows the pattern <arn:aws:iam::<account-id>:oidc-provider/<provider-path>"

#### `policies` (`object`)

The map of all policy ARNs that you want to attach to the role.

- **Title**: Policies
- **Description**: The map of all policy ARNs that you want to attach to the role
- **Pattern Properties**:
  - **type** (`object`): Policy ARN
    - **Title**: Policy ARN
    - **Key Pattern**: '^[a-zA-Z0-9_.-]*$'
    - **Description**: An arbitrary name given to the policies which is not used anywhere
    - **Properties**:
      - **arn** (`string`): The ARN of the policy that you want to attach the role.
        - **Description**: The ARN of the policy that you want to attach the role
        - **Pattern**: '^arn:[a-zA-Z0-9-]+:[a-zA-Z0-9-]+:[a-zA-Z0-9-]*:[0-9]{12}:[a-zA-Z0-9-\/:_+=.@]+$'
        - **UI Error Message**: "Invalid ARN format. Ensure it follows the pattern <arn:partition:service:region:account-id:resource>"

---

## Usage

Use this module to create and manage AWS IAM roles. It is especially useful for:

- Defining the characteristics and behavior of IAM roles
- Managing access and permissions for AWS resources
- Enhancing the security and functionality of AWS applications
