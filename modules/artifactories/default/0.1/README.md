# Artifactories Module

## Overview

This module provisions **container registry credentials as Kubernetes secrets** from configured container registries (referred to as *artifactories*) within your project. These secrets can be used by workloads to authenticate with registries such as DockerHub, JFrog Artifactory, GitHub Container Registry, etc.

It supports two modes:

- Including **all container registries** mapped to the current project.
- Defining a **custom list** of container registries by name.

The secrets are generated automatically and injected into the associated Kubernetes cluster for use in imagePullSecrets or custom workloads.

## Inputs

This module requires an input reference to the target Kubernetes cluster.

- **`kubernetes_details`**:  
  A reference to the Kubernetes cluster where registry secrets should be created. This input is automatically populated with the default Kubernetes cluster unless overridden.

## Configurability

- `metadata`: 
  Metadata block for resource description or naming overrides. Can be left empty.

---

**`spec`**

Defines whether to include all registries or specify selected registries.

- **`include_all`**:  
  If set to `true`, all container registries mapped to the project will be included, and the `artifactories` field should be omitted.

- **`artifactories`**: 
  A map of container registry identifiers to their names. This should be used only if `include_all` is `false`. Each entry must include a `name` property that matches a registry defined in the control plane.

## Usage

When the Artifactories module is included in your blueprint:

It will create Kubernetes image pull secrets for container registries defined in the project.

These secrets are injected into the target Kubernetes cluster and can be referenced by workloads using imagePullSecrets.

You can choose to:

Include all registries mapped to the project by enabling the include_all flag.

Manually specify registries using the artifactories block if you only want secrets for specific registries.

The module ensures each secret corresponds to the correct credentials of the associated container registry.

These secrets simplify the process of authenticating private container image pulls for deployments across your environments.

