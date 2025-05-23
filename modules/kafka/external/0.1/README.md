# Kafka External Module

## Overview

This module integrates an **external Kafka cluster** into your Facets environment using the `external` flavor. It allows you to securely reference an already existing Kafka service (outside of Facets) by providing the endpoint, authentication credentials, and full connection string.

This is useful in cases where Kafka is managed by a third party, shared across teams, or already deployed using different tooling or environments.

## Configurability

This module requires the external Kafka connection details to be provided through the `spec` block.

---

- **`metadata`** 
  Metadata related to the resource, such as a custom name. Can be left empty if default naming is sufficient.

---
The `spec` block contains the required fields to connect to an external Kafka instance.

- **`endpoint`**: 
  The Kafka broker endpoint in the format `host:port`.  
  Example: `kafka.example.com:9092`

- **`username`**: 
  Username used to authenticate with the Kafka cluster.

- **`password`**: 
  Password used with the provided username for authentication.

- **`connection_string`**:  
  The full Kafka connection string including protocol, credentials, and brokers.  
  Example: `kafka://user:pass@broker1:9092,broker2:9092`

---

## Usage

Once configured, the module will:

- Make the external Kafka broker information available to other Facets resources.
- Allow dependent services or consumers (e.g., Kafka producers, stream processors) to consume `connection_string`, `endpoint`, and authentication credentials.
- Act as a credential store and endpoint reference — no Kafka infrastructure is provisioned by this module.


## Notes 
Both endpoint and connection_string are mandatory fields.

The connection_string must start with the prefix kafka:// and include credentials and broker information in the format:
kafka://<username>:<password>@<host>:<port>[,<host>:<port>...]

If using authentication, both username and password should be securely referenced from secrets.

This module does not provision Kafka itself — it is intended for referencing an existing Kafka service