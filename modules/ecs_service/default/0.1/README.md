# ECS Service Module


## Overview

**Flavor**: default  
**Version**: 0.1
This module provisions a **containerized application** on AWS ECS using Fargate. It allows platform users to deploy Docker containers declaratively by specifying the container image, resource requirements, port mappings, environment variables, and autoscaling configuration.

This module supports **AWS** cloud environments and integrates with existing VPC and ECS cluster infrastructure.

## Configurability

`metadata`
* `metadata`: Optional metadata for the ECS service.

`spec`

`runtime`: Defines the container runtime configuration.
* `ports`: Port mappings between container and host. *Example*: `port: "80"`
* `size`: CPU and memory resource allocation. *Example*: `cpu: 512`, `memory: 1`
* `command`: Override the default container command.
* `args`: Command-line arguments for the container.
* `readonly_root_filesystem`: Mount container's root filesystem as read-only.

`release`: Defines the container image to deploy.
* `image`: The Docker image URL. *Example*: `nginx:1.21`


## Usage

Once configured and deployed:
* The specified Docker container will be deployed to your ECS cluster using Fargate.
* The service will automatically create security groups allowing VPC-internal communication.
* Environment variables are securely stored in AWS Secrets Manager and injected at runtime.
* If autoscaling is configured, the service will scale based on CPU and memory utilization.
* The container will run with the specified resource limits and port mappings.
