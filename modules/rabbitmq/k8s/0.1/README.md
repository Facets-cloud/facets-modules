# RabbitMQ Module (Kubernetes)

## Overview

This RabbitMQ module deploys a scalable and configurable RabbitMQ cluster on Kubernetes. It supports multiple cloud platforms including AWS, Azure, GCP, and vanilla Kubernetes. Teams can define specific RabbitMQ versions, control CPU/memory sizing, set resource limits, and scale instances easily.

## Configurability

- **RabbitMQ Version**  
  - Choose from predefined versions: `3.10.7`, `3.10.19`.

- **Size Configuration**
  - **CPU / CPU Limit**: Set base and maximum CPU resources (e.g., `500m`, `2`).
  - **Memory / Memory Limit**: Set base and max memory (e.g., `512Mi`, `2Gi`).
  - **Volume**: Define the size of the persistent volume (e.g., `8Gi`).
  - **Instance Count**: Number of RabbitMQ instances (1–100).

## Usage

Use this module to deploy RabbitMQ clusters with production-grade resource management and horizontal scalability. Ideal for cloud-native environments where control over compute, memory, and volume resources is essential.
