# Kubernetes Resource Module

## Overview

This Terraform module allows you to deploy arbitrary **Kubernetes resources** into your cluster. It supports cloud-native Kubernetes environments as well as managed clusters on:

- AWS (e.g., EKS)
- Azure (e.g., AKS)
- GCP (e.g., GKE)
- Kubernetes

It is especially useful when you want to deploy native Kubernetes objects such as Services, Deployments, ConfigMaps, CRDs, or any custom resources that are **not abstracted by a higher-level module**.

## Configurability

The module accepts the following parameters under the `spec` block:

**Required**

- **`resource`** –  A single Kubernetes manifest. This represents the main resource to be deployed in the cluster. You can only provide **one manifest** here. Use `additional_resources` to deploy more.

### Optional

- **`additional_resources`** –  
  A collection of additional Kubernetes resources that you want to deploy alongside the main `resource`. Each key should be a unique name or identifier, and the corresponding value should contain a Kubernetes manifest. These are useful for attaching related configurations like ConfigMaps, Roles, etc.

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




