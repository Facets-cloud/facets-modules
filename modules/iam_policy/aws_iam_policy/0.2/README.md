# AWS IAM Policy Module

## Overview

This Terraform module provisions an **AWS IAM Policy** using a custom-defined policy document. It allows platform teams and developers to define reusable, versioned IAM policies in YAML format, which can then be attached to IAM users, groups, or roles.

This module is cloud-specific and supports only **AWS**.

---

## Configurability

The following parameters can be configured under the `spec` block:

### ✅ metadata

- `metadata`: *(optional)*  
  Optional metadata block for tagging or naming the resource. Can be left empty.

### ✅ spec

#### `name`: *(string, required)*  
The name of the IAM policy to be created.  
- Must be unique within the AWS account.  
- Example: `s3-read-policy`, `eks-full-access`.

#### `policy`: *(object, required)*  
The policy document in **YAML format**, which defines allowed or denied AWS actions.  
This follows the standard AWS IAM policy structure but is expressed in YAML for clarity.

## Usage

When you define this module with the name and policy fields:

A new IAM policy will be created in your AWS account.

You can attach this policy to IAM users, groups, or roles using other modules or Terraform resources.

Updates to the policy document will trigger an in-place policy update while maintaining version tracking.




