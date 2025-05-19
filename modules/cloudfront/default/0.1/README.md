# AWS CloudFront Module

## Overview

The AWS CloudFront module provisions and manages CloudFront distributions on AWS, enabling fast and secure content delivery with fine-grained control over caching, origins, and viewer certificate configuration. It supports declarative setup of CloudFront resources tailored for global CDN use cases with customizable caching policies, HTTPS enforcement, and Web Application Firewall integration.

## Configurability

- **Aliases**: Define custom domain aliases (including wildcard domains) for the CloudFront distribution.  
- **Viewer Certificate**: Configure ACM certificates for HTTPS support with secure viewer certificates.  
- **Origins**: Specify one or more origins where CloudFront forwards requests, including domain names and origin-specific configurations.  
- **Cache Policies**: Create detailed cache policies controlling TTL (max, min, default) and parameters included in cache keys and forwarded to origins, such as cookies, headers, and query strings.  
- **Default Cache Behavior**: Set the default behavior for caching, allowed HTTP methods, cached methods, and viewer protocol policy (HTTP/HTTPS access control).  
- **Ordered Cache Behaviors**: Define ordered cache behaviors with path patterns to customize caching and routing for specific URL patterns, including compression options.  
- **AWS WAF Integration**: Attach an AWS Web Application Firewall (WAF) ID to protect your distribution from web threats.

## Usage

This module allows teams to deploy AWS CloudFront distributions with production-ready configurations optimized for performance, security, and flexibility.

Common use cases:

- Distributing web assets with global low-latency CDN  
- Configuring secure HTTPS delivery with ACM certificates  
- Defining custom cache policies for optimizing content freshness and origin load  
- Routing specific URL paths with tailored caching and compression behaviors  
- Protecting web applications using AWS WAF integration  
- Automating CloudFront setup in infrastructure-as-code and CI/CD pipelines
