# AWS WAF Module

## Overview

The `aws_waf - default` flavor (v0.1) enables the creation and management of AWS Web Application Firewall (WAF) configurations. This module provides configuration options for defining the characteristics and behavior of WAF.

Supported clouds:
- AWS

## Configurability

- **Scope**: Scope of the WAF (REGIONAL or CLOUDFRONT).
- **Rule Groups**: Configuration for rule groups in WAF.
- **Resource ARNs**: Configuration for resource ARNs in WAF.
- **Default Action**: Configuration for the default action when no rule explicitly allows or blocks the request, the default action is applied which is allow.

## Usage

Use this module to create and manage AWS WAF configurations. It is especially useful for:

- Defining the characteristics and behavior of WAF
- Managing security rules and policies for web applications
- Enhancing the security and protection of AWS-hosted applications
