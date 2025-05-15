# GCP IAM Role - Default Flavor

## Overview

The `gcp_iam_role` intent with the `default` flavor allows declarative creation and management of custom IAM roles in Google Cloud Platform (GCP). It supports defining role properties such as permissions, base roles, and role lifecycle stage. This module helps enforce consistent IAM policies and access controls across GCP projects.

It is designed for use in infrastructure as code workflows to simplify role provisioning, updating, and governance.

## Configurability

Key configurable properties under the `spec` section include:

- **role_id**  
  Unique identifier for the custom IAM role.

- **stage**  
  Role lifecycle stage, e.g., `GA` (Generally Available).

- **base_roles**  
  A list of existing roles whose permissions are inherited.

- **permissions**  
  Explicit list of permissions granted by this role.

- **excluded_permissions**  
  Permissions to exclude from the base roles.

- **title**  
  Human-readable title for the role.

These options enable precise control over the role’s access scope and management lifecycle.

## Usage

This module is used to create and manage custom IAM roles within GCP projects. Common scenarios include:

- Defining roles tailored to specific team or application needs.  
- Combining multiple base roles with custom permissions for fine-grained access control.  
- Automating role updates and ensuring consistent policy enforcement across environments.

By using this intent, organizations improve security posture through reproducible IAM role management.
