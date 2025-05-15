# Kubernetes Resource Module

## Overview

This Terraform module provisions native **Kubernetes resources** using raw **YAML manifests**. It is designed for platform teams that need direct control over Kubernetes object definitions and is compatible with clusters running on:

- AWS (EKS)
- Azure (AKS)
- GCP (GKE)
- Kubernetes**

This module allows you to define and apply one or more Kubernetes manifests in a declarative and version-controlled manner.

---

## Configurability

The following parameters are supported under the `spec` block:

### Required

- **`resource`** (`object`) –  
  The main Kubernetes manifest to be deployed, written in **YAML** format.  
  > You may only define **one manifest** in this field. To define multiple, use `additional_resources`.

---

### Optional

- **`additional_resources`** (`map(object)`) –  
  A collection of additional Kubernetes manifests. Each key in this map must follow a numeric pattern (e.g., `"01"`, `"02"`), and each value must contain a `configuration` block with a valid Kubernetes manifest.

## Usage

This module provisions the following:

Primary Kubernetes Resource – Defined in the resource block using a YAML manifest.

Additional Resources – A set of related Kubernetes manifests defined under `additional_resources`.

You can use this module to create:
1. Services

2. Deployments

3. Ingresses

4. Secrets

5. CustomResourceDefinitions (CRDs)

6. Any custom Kubernetes resource

