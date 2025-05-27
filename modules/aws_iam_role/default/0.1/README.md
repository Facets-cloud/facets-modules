# AWS IAM Role – Default Flavor (v0.1)

## Overview

The `aws_iam_role - default` flavor (v0.1) enables the creation and management of AWS IAM roles. This module provides configuration options for defining the characteristics and behavior of the IAM roles.

Supported platforms:
- AWS

## Configurability

- **IRSA**: Configuration to attach EKS OIDC to service accounts for allowing applications to get cloud credentials.
    - **Service Accounts**: The map of all service accounts that you want to attach IRSA.
        - **Service Account Name**: An arbitrary name given to the service account keys which is not used anywhere
        - **Name**: The actual name of the service account that you want to attach the role to with the trust
          relationship.
    - **OIDC Providers**: The map of all OIDC ARNs that you want to attach IRSA.
        - **OIDC Provider ARN**: An arbitrary name given to the OIDC provider keys which is not used anywhere
            - **ARN**: The ARN of the OIDC that you want to attach the role to with the trust
              relationship.
- **Policies**: The map of all policy ARNs that you want to attach to the role.
    - **Policy ARN**: An arbitrary name given to the policies which is not used anywhere
    - **ARN**: The ARN of the policy that you want to attach the role.

---

## Usage

Use this module to create and manage AWS IAM roles. It is especially useful for:

- Defining the characteristics and behavior of IAM roles
- Managing access and permissions for AWS resources
- Enhancing the security and functionality of AWS applications
