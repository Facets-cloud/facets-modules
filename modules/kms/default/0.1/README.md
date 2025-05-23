# AWS KMS Module

## Overview

This Terraform module provisions an [AWS Key Management Service (KMS)](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) key and manages its lifecycle, configuration, and access control. It supports the creation of customer-managed keys (CMKs), key policies, grants, aliases, automatic rotation, and optional replication across multiple regions. This module is designed to be flexible and suitable for both internal and external key usage, with enhanced support for AWS services like Route53 DNSSEC and autoscaling integrations.

## Configurability

The following input parameters are supported under the `spec` block:

- **`create_external`** – Whether to create an external key.
- **`bypass_policy_lockout_safety_check`** – Bypass AWS safety checks for key policy.
- **`customer_master_key_spec`** – CMK spec (e.g., `SYMMETRIC_DEFAULT`, `RSA_2048`).
- **`custom_key_store_id`** – ID of the custom key store (CloudHSM).
- **`deletion_window_in_days`** – Days before key deletion (min: 7, max: 30).
- **`description`** – Text description of the key.
- **`enable_key_rotation`** – Enable auto-rotation (only for symmetric keys).
- **`is_enabled`** – Whether the key is enabled on creation.
- **`key_material_base64`** – Base64 key material (used with import).
- **`key_usage`** – Use type (`ENCRYPT_DECRYPT`, `SIGN_VERIFY`, etc.).
- **`multi_region`** – Enable multi-region key support.
- **`policy`** – Custom key policy JSON.
- **`valid_to`** – Expiration time for the key.
- **`enable_default_policy`** – Attach default AWS KMS policy.
- **`key_owners`, `key_administrators`, `key_users`** – IAM principals.
- **`key_service_users`, `key_service_roles_for_autoscaling`** – Service-linked roles.
- **`key_symmetric_encryption_users`, `key_hmac_users`** – Symmetric & HMAC users.
- **`key_asymmetric_public_encryption_users`, `key_asymmetric_sign_verify_users`** – Asymmetric key users.
- **`key_statements`** – Additional IAM policy statements.
- **`source_policy_documents`, `override_policy_documents`** – Policy layering control.
- **`enable_route53_dnssec`** – Enable Route53 DNSSEC integration.
- **`route53_dnssec_sources`** – Sources for DNSSEC trust.
- **`rotation_period_in_days`** – Custom rotation interval (1–365 days).
- **`create_replica`** – Create cross-region replica.
- **`primary_key_arn`, `primary_external_key_arn`** – Source key ARN for replica.
- **`create_replica_external`** – Create external replica.
- **`aliases`** – Key aliases like `alias/my-key`.
- **`computed_aliases`** – Dynamically generated aliases.
- **`aliases_use_name_prefix`** – Prefix aliases with context.
- **`grants`** – Key grants in JSON.

## Usage

- **KMS Key Policy** – A user-defined or default IAM policy governing key access control.

- **KMS Key Aliases** – One or more user-defined or computed aliases to simplify referencing the key.

- **KMS Grants** – Optional fine-grained key grants allowing access to specific AWS services or IAM roles.

- **Replica Keys** – If enabled, creates replica keys in additional regions for cross-region support and high availability.

- **Route53 DNSSEC Configuration** – (Optional) Integrates the key with Route53 for DNSSEC signing of hosted zones.

All of these resources are driven by the fields set under the `spec` block of the module. See the [Configurability](#configurability) section for all supported input parameters.
