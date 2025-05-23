# Kafka User Module

## Overview 

This module provisions a **Kafka user resource** within a Kafka cluster using the `default` flavor. It is designed to support authentication and authorization scenarios where users are required to interact with Kafka topics or other cluster resources. This module acts as a foundational identity object for clients or services consuming or producing data via Kafka.

It is typically used in conjunction with Kafka modules such as MSK or Kubernetes-based Kafka clusters, and enables secure, programmatically managed user creation for Kafka access.

## Configurability

The Kafka User module supports a minimal configuration interface for now. It is designed to be extended in the future to support specific features such as SASL users, ACL bindings, etc.

- *(Currently Empty)*  
  The `spec` field is reserved for future extensions where Kafka user configuration (e.g., username, credentials, ACLs) will be defined.

Even though no user-level configuration exists today, declaring this resource ensures identity linkage within the broader blueprint and allows future enhancements without breaking compatibility.

## Usage

Once configured:

- A logical Kafka user will be provisioned within the Kafka management context.
- It can be referenced by downstream modules for permission bindings or topic access.
- Acts as a placeholder for service identity or credential provisioning.

This module is especially useful in IaC-driven Kafka environments where access control and identity management are modeled declaratively.

## Notes

- The module is forward-compatible and will support detailed user specs (ACLs, SASL, etc.) in upcoming versions.
- Currently, the Kafka user identity acts as a resource marker, and integrations may rely on internal conventions for linking user access.



