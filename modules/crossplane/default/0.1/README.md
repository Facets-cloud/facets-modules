# Crossplane Module

## Overview

The Crossplane module installs and manages Crossplane on Kubernetes clusters across multiple cloud providers including AWS, GCP, Azure, and Kubernetes itself. It enables cloud-native infrastructure orchestration and multi-cloud resource provisioning through a declarative and extensible approach.

## Configurability

- **Multi-cloud support**: Deploy Crossplane on Kubernetes clusters running on AWS, GCP, Azure, or any Kubernetes environment.  
- **Instance sizing**: Customize CPU and memory limits for the Crossplane instance with precise validation patterns to ensure valid resource requests.  
- **Flexible configuration values**: Pass arbitrary YAML-formatted values to customize the Crossplane deployment or Helm chart.  
- **Kubernetes cluster integration**: Requires Kubernetes cluster details where Crossplane will be installed, supporting smooth integration with existing infrastructure.  
- **Lifecycle management**: Designed as an environment-level component to manage Crossplane lifecycle as part of your deployment pipeline.

## Usage

This module is ideal for teams looking to deploy Crossplane in a consistent, repeatable manner on Kubernetes clusters across multiple clouds. Use cases include:

- Enabling multi-cloud infrastructure orchestration and governance  
- Deploying Crossplane as part of environment setup and management  
- Controlling resource allocation through configurable CPU and memory limits  
- Passing custom Helm chart values for advanced Crossplane configuration  
- Automating Crossplane deployment in CI/CD workflows and infrastructure-as-code pipelines
