# Kafka User Module

## Overview

This Terraform module provisions a **Kafka user** in a specified Kafka cluster. It supports deployment across multiple cloud platforms including **AWS**, **GCP**, **Azure**, and **Kubernetes**, making it ideal for hybrid and multi-cloud environments. The Kafka user can be used to authenticate and authorize access to Kafka topics and services, and is created in the environment specified via `kafka_details`. This module is a lightweight, cloud-agnostic wrapper designed to abstract the underlying infrastructure details of Kafka user provisioning.

## Configurability

The following input parameters are supported under the `spec` block:

- **`kafka_details`**  
  A reference to the Kafka cluster where the user should be created.  
  This is typically provided as a dependency output from a Kafka provisioning module.

## Usage

This module provisions the following:

- **Kafka User** – A named user within the target Kafka cluster. 
- **Cloud Agnostic Deployment** – Compatible with Kafka clusters running on:
  - AWS 
  - GCP 
  - Azure 
  - Kubernetes





