# Atlas Account Module

## Overview

This module provisions and authenticates access to a **MongoDB Atlas Account** using the `default` flavor. It securely configures credentials required to interact with Atlas resources (e.g., clusters, databases, backups) by setting up a project-level authentication context.
This module is intended to be used as a foundational block in environments where other modules depend on MongoDB Atlas APIs, such as those provisioning clusters, users, or database automation.

## Configurability

The module requires three primary fields under `spec` to connect and authenticate with the Atlas project.

---

### ✅ metadata

- `metadata`: *(optional)*  
  Descriptive or identifying metadata for the resource. Can be left empty.

---

### ✅ spec

Defines the credentials and project context for interacting with the Atlas API.

- `project_id`: *(string, required)*  
  The MongoDB Atlas project ID. This determines the project scope for all resource provisioning.

- `public_key`: *(string, required)*  
  The Atlas public API key with appropriate access to manage resources in the specified project.

- `private_key`: *(string, required)*  
  The corresponding private API key. Ensure this is securely stored and retrieved via secrets management.

---

### ✅ lifecycle

- `lifecycle`: *(optional, default: ENVIRONMENT)*  
  Indicates the phase during which this module should be initialized. Set to `ENVIRONMENT` to provision it as part of environment setup.

---

### ✅ depends_on (Optional)

- `depends_on`: *(array)*  
  An optional list of dependencies if other resources must be provisioned before this one.

---

### ✅ advanced (Optional)

- `advanced`: *(object)*  
  Currently reserved for future customization and advanced use cases.

## Usage

This module is used to establish secure access to MongoDB Atlas APIs.

The module should be included early in your blueprint to ensure credentials are available before dependent modules initialize.

**Best Practice**: Reference all sensitive fields (`project_id`, `public_key`, `private_key`) via blueprint variables and secrets, rather than hardcoding them. This enhances security and reuse.

## Notes
Ensure the public and private keys belong to an API key that has sufficient privileges in the specified Atlas project.

Secrets should be managed securely using the platform's built-in secret management system.

This module must be configured before any module that depends on authenticated access to MongoDB Atlas.

If you are using multiple Atlas projects, define a separate instance of this module for each.