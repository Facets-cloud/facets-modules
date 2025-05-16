# Kafka User Module (External Flavor)

## Overview

This module provisions a **Kafka user identity** for **externally managed Kafka clusters**, such as MSK or self-hosted Kafka. It enables clients to authenticate with the Kafka broker using externally defined credentials (username and password). This module is intended for use in secure, externally integrated Kafka environments where authentication credentials are pre-provisioned or externally managed.

It does **not** create users within Kafka itself but allows users to declare and reference Kafka credentials within the infrastructure-as-code blueprint.

## Configurability

The following fields are available under the `spec` block:

### ✅ `username` *(string, required)*  
The username that will be used to authenticate with the Kafka broker.  
This is typically configured when the broker requires SASL authentication.

### ✅ `password` *(string, required)*  
The corresponding password for the Kafka user.  
Sensitive and should be stored using the platform's secrets manager or secret reference mechanism.

## Usage

Once configured:

- The credentials (username and password) will be used by clients or services to connect to an external Kafka cluster.
- This resource acts as a declarative reference to credentials used for producing or consuming messages.
- Downstream modules such as applications or Kafka topic bindings may reference this user for secure access.

This module is **non-intrusive** and expects the actual user to already exist in the Kafka cluster or be created via another mechanism.

## Notes
This module is intended to declare credentials for externally managed Kafka, not to create them.

It does not perform user provisioning or ACL management inside Kafka.

For secure usage, reference the password via secret management and avoid hardcoding credentials directly in the spec.

Ensure the Kafka broker is configured to accept SASL authentication for the specified user.

