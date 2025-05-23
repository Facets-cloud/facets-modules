# AWS Static Website – Default Flavor (v0.1)

## Overview

The `aws_static_website - default` flavor (v0.1) enables the creation and management of static websites hosted on AWS. This module provides configuration options for defining the characteristics and behavior of the static website.

Supported platforms:
- AWS

## Configurability

### Spec

#### `website` (object)

Defines the configuration for the static website.

- **source_code_s3_path** (`string`)  
  The S3 path to the source code zip file for the website.
  
- **cloudfront_enabled** (`boolean`)  
  Specifies whether CloudFront should be enabled for the website.

---

## Usage

Use this module to create and manage static websites hosted on AWS. It is especially useful for:

- Hosting static websites
- Managing the deployment and distribution of website content
- Enhancing the performance and reliability of static websites
