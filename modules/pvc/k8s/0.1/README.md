# PVC Module

## Overview

This PVC module provisions a persistent volume claim (PVC) for Kubernetes workloads across AWS, Azure, GCP, and vanilla Kubernetes environments. It enables teams to define consistent and compliant volume sizing for stateful applications.

## Configurability

- **Volume Size**  
  - Define the volume size using a valid format like `10Gi`, `50Gi`, etc.  
  - Must be greater than `0Gi`.

## Usage

Use this module to attach persistent storage to your Kubernetes pods with predictable sizing. Ideal for stateful apps like databases, caches, or file systems that require durable storage.
