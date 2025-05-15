# AWS API Gateway Module

## Overview

This module provisions an **AWS API Gateway** using the `default` flavor, enabling you to configure and manage RESTful or WebSocket APIs on AWS. It supports HTTP route configuration, Lambda/HTTP/Mock integrations, optional domain name bindings, CORS settings, authorizers, VPC links, mutual TLS, and other advanced settings through a consistent Terraform-based interface.

Use this module to expose backend services through a fully managed API Gateway with fine-grained access, logging, and integration controls.

## Configurability

The configuration has three core components: `metadata`, `spec`, and optional `advanced.aws_api_gateway`.

### ✅ metadata

The `metadata` section provides general information about the resource.

- `description`: *(string, required)*  
  A human-readable summary describing the purpose of the API Gateway.

### ✅ spec

The `spec` section defines the core behavior of the API Gateway.

- `protocol`: *(string, required)*  
  Specifies the type of API. Supported values: `HTTP`, `WEBSOCKET`.

- `integrations`: *(map, required)*  
  A map where each key represents an HTTP method and path (e.g., `GET /users`), and the value provides integration details such as the Lambda ARN and type of integration.  

### ✅ advanced

The **`advanced`** section allows additional customization of the API Gateway.

- **`cors`**:
Configure Cross-Origin Resource Sharing with properties like allow_methods, allow_origins, and allow_headers.

- **`authorizers`**:
Attach Lambda or JWT-based authorizers to control access to API routes.

- **`domain_name`** and domain_name_certificate_arn:
Bind the API Gateway to a custom domain name secured via ACM.

- **`create_default_stage`** and create_default_stage_api_mapping:
Enable automatic creation and mapping of a default deployment stage.

- **`default_stage_access_log_destination_arn`** and default_stage_access_log_format:
Define access log destination and format for stage-level logging.

**`mutual_tls_authentication`**:
Configure mutual TLS authentication using an S3 truststore.

- **`vpc_links`**:
Define VPC link resources to support private integrations with services running in VPCs.

- **`tags`**:
Assign metadata tags to the API Gateway resources.

## Usage

This module allows you to expose HTTP-based microservices or Lambda functions as RESTful endpoints with custom routing and integration behavior. You can:

- Define one or more HTTP paths and methods under `spec.integrations`
- Connect them to backend integrations like AWS Lambda, HTTP endpoints, or mock responses
- Configure CORS and authentication if needed
- Attach a domain name and secure it with a certificate via ACM
- Enable CloudWatch logs for visibility
- Use `advanced` options for VPC link connectivity, mutual TLS, and fine-grained stage behavior


## Notes
At least one integration route must be defined (e.g., GET /).

If using a custom domain, the associated ACM certificate must exist in the same AWS region.

Lambda functions used in AWS_PROXY integrations must have lambda:InvokeFunction permission for the API Gateway service.

If using authorizers, ensure that all required fields such as name, authorizer_uri, and identity_sources are configured properly.

Use execution_arn or stage_execution_arn in your IAM policies or aws_lambda_permission resources for allowing API Gateway to invoke downstream services.



