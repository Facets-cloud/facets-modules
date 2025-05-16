# OpenSearch Module (Elasticsearch Intent)

## Overview

This module provides a configurable OpenSearch (Elasticsearch-compatible) deployment designed for AWS environments.  
It supports multiple versions of OpenSearch and offers extensive customization options including sizing, security, access policies, logging, and advanced cluster configurations.  
The module is intended to simplify deployment and management of OpenSearch domains tailored to your infrastructure and security requirements.

---

## Configurability

The module configuration is expressed as a detailed specification object allowing you to customize:

- **OpenSearch version:** Select supported OpenSearch versions (e.g., 2.17, 2.15, etc.).
- **Sizing:** Specify instance type, count, and storage volume size.
- **Network privacy:** Option to make the domain private.
- **Security:** Enable advanced security options, authentication methods, master user settings.
- **Access Policies:** Define and enforce IAM-based access policies.
- **Logging:** Configure CloudWatch log groups, retention, and publishing options.
- **Cluster & EBS options:** Customize cluster configuration, EBS volumes, encryption, node-to-node encryption.
- **Auto-tuning:** Enable or disable auto-tune options.
- **Additional features:** SAML options, security group management, domain endpoint options, software updates, VPC endpoints, and more.

The flexibility ensures compatibility with diverse deployment needs, security postures, and operational policies.

---

## Usage

### Prerequisites

- AWS environment with appropriate permissions for OpenSearch and IAM.
- Configured AWS VPC for networking.
- Knowledge of OpenSearch domain configuration and AWS best practices.

### Steps to Deploy

1. **Clone the repository or obtain the module**  
   ```bash
   git clone https://github.com/yourorg/yourrepo.git
   cd yourrepo
