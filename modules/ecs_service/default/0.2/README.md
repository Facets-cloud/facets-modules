# ECS Service Module - Default Flavor v0.2


## Overview
A Terraform module for deploying containerized applications to AWS ECS using Fargate. This module creates a complete ECS service with security groups, IAM roles, and secrets management.
This module deploys a Docker container as an ECS service on AWS Fargate. It handles container runtime configuration, networking, security, and integrates with AWS Secrets Manager for environment variable management. The module supports custom container registries and IAM policy attachments for cloud permissions.

## Configurability

The module provides extensive configuration options through the `spec` block:

- **Runtime Configuration**: CPU and memory allocation, port mappings, command overrides, and read-only filesystem settings
- **Release Management**: Docker image specification with support for custom container registries
- **Environment Variables**: Secure environment variable injection with pattern-based configuration
- **Cloud Permissions**: AWS IAM policy attachments for fine-grained access control
- **Auto-scaling**: Configurable minimum and maximum instance counts with CPU and memory-based scaling policies
- **Advanced Settings**: Circuit breaker configuration, placement constraints, and service connect options

Key configurable parameters include container resource sizing (512-4096 CPU units, 1-30GB memory), multiple port configurations with TCP/UDP protocol support, and flexible environment variable management through AWS Secrets Manager integration.

## Usage

This module requires two primary inputs:
- **Network Details** (`@outputs/aws_vpc`): VPC configuration for networking and security group placement
- **ECS Cluster Details** (`@outputs/ecs_cluster`): Target ECS cluster for service deployment

The module also requires a Docker image artifact specified at `spec.release.image` path. Both inputs have default resource references (network uses `default` network resource, ECS uses `default` ecs_cluster resource) but can be overridden to point to specific infrastructure resources.

The module automatically creates necessary AWS resources including ECS service, task definition, IAM roles, security groups, and AWS Secrets Manager secrets for secure container deployment on Fargate.
