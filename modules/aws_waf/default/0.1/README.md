# AWS WAFv2 Web ACL – Default Flavor (v0.1)

## Overview

The `aws_wafv2_web_acl` module enables the creation and management of AWS WAFv2 Web ACLs. This module provides configuration options for defining the characteristics and behavior of the Web ACLs.

Supported platforms:
- AWS

## Configurability

### Spec

#### `module "name"` (object)

Defines the module configuration for AWS WAFv2 Web ACL.

- **source** (`string`)  
  The source of the module.
  
- **environment** (`string`)  
  The environment variable.
  
- **limit** (`number`)  
  The limit for the resource.
  
- **resource_name** (`string`)  
  The name of the resource.
  
- **resource_type** (`string`)  
  The type of the resource.
  
- **globally_unique** (`boolean`)  
  Specifies whether the resource name should be globally unique.
  
- **is_k8s** (`boolean`)  
  Specifies whether the resource is Kubernetes-related.

---

### Resource Configuration

#### `aws_wafv2_web_acl` (object)

Defines the AWS WAFv2 Web ACL resource.

- **custom_response_body** (`object`)  
  Custom response body configuration.
  
- **default_action** (`object`)  
  Default action configuration.
  
- **description** (`string`)  
  Description of the Web ACL.
  
- **name** (`string`)  
  Name of the Web ACL.
  
- **rule** (`object`)  
  Rule configuration.
  
- **scope** (`string`)  
  Scope of the Web ACL.
  
- **tags** (`object`)  
  Tags for the Web ACL.
  
- **visibility_config** (`object`)  
  Visibility configuration.

#### `aws_wafv2_web_acl_association` (object)

Defines the AWS WAFv2 Web ACL association resource.

- **resource_arn** (`string`)  
  ARN of the resource to associate with the Web ACL.
  
- **web_acl_arn** (`string`)  
  ARN of the Web ACL.

---

## Usage

Use this module to create and manage AWS WAFv2 Web ACLs. It is especially useful for:

- Defining the characteristics and behavior of Web ACLs
- Managing the rules and actions for Web ACLs
- Enhancing the security and protection of web applications
