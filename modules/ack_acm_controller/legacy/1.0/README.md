# ACK ACM Controller (Legacy)

Deploys the AWS Controllers for Kubernetes (ACK) ACM Controller on EKS clusters, enabling management of AWS Certificate Manager certificates as Kubernetes resources.

## Overview

This module installs the ACK ACM Controller via Helm and configures IAM Role for Service Accounts (IRSA) so the controller can manage ACM certificates. Once deployed, you can create `Certificate` custom resources in Kubernetes that provision real ACM certificates and export them to Kubernetes TLS secrets.

This is primarily used by the `nginx_gateway_fabric_legacy_aws` module to handle domains with ACM ARN `certificate_reference`.

## Architecture

```
  ┌──────────────────────────────────────────┐
  │           ACK ACM Controller             │
  │                                          │
  │  1. Watches Certificate CRDs             │
  │  2. Calls ACM API via IRSA               │
  │  3. Requests/validates certificates      │
  │  4. Exports cert to K8s TLS secret       │
  │                                          │
  │  IAM: acm:RequestCertificate,            │
  │       acm:DescribeCertificate,           │
  │       acm:GetCertificate, ...            │
  └──────────────────────────────────────────┘
          │                          │
          ▼                          ▼
   AWS ACM (Certificate)     K8s TLS Secret
   (DNS validation)          (exported cert)
```

## What It Creates

| Resource | Description |
|----------|-------------|
| `aws_iam_policy` | IAM policy granting ACM permissions |
| IRSA module | IAM role bound to the controller's service account |
| `helm_release` | ACK ACM Controller deployment from `oci://public.ecr.aws/aws-controllers-k8s/acm-chart` |

## Configuration

### Basic Example

```json
{
  "kind": "ack_acm_controller",
  "flavor": "legacy",
  "version": "1.0",
  "spec": {
    "chart_version": "1.3.4"
  }
}
```

### With Custom Namespace

```json
{
  "kind": "ack_acm_controller",
  "flavor": "legacy",
  "version": "1.0",
  "spec": {
    "chart_version": "1.3.4",
    "namespace": "cert-manager"
  }
}
```

## Spec Options

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
| `chart_version` | string | `1.3.4` | Yes | Helm chart version of the ACK ACM Controller |
| `namespace` | string | environment namespace | No | Kubernetes namespace for the controller |
| `helm_values` | object | - | No | Additional Helm values to override defaults |

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `kubernetes_details` | `@outputs/kubernetes` | Yes | Kubernetes cluster connection (provides OIDC provider ARN for IRSA) |

## Outputs

| Attribute | Description |
|-----------|-------------|
| `namespace` | Namespace where the controller is deployed |
| `release_name` | Helm release name |
| `chart_version` | Deployed chart version |
| `role_arn` | IAM role ARN used by the controller |
| `helm_release_id` | Helm release ID |

## Usage with nginx_gateway_fabric_legacy_aws

Once deployed, the `nginx_gateway_fabric_legacy_aws` module can use ACM ARNs as `certificate_reference` on domains:

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_aws",
  "version": "1.0",
  "spec": {
    "domains": {
      "production": {
        "domain": "api.example.com",
        "alias": "prod",
        "certificate_reference": "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
      }
    }
  }
}
```

The ingress module detects the ACM ARN, creates a `Certificate` CRD (kind: `acm.services.k8s.aws/v1alpha1`), and the ACK controller provisions the certificate and exports it to a K8s TLS secret.

## Prerequisites

- EKS cluster with OIDC provider configured
- Route53 hosted zone for DNS validation of ACM certificates

## Troubleshooting

### Check Controller Status

```bash
kubectl get pods -n <namespace> -l app.kubernetes.io/name=acm-chart
kubectl logs -n <namespace> -l app.kubernetes.io/name=acm-chart
```

### Check ACM Certificate CRDs

```bash
kubectl get certificate.acm.services.k8s.aws -n <namespace>
kubectl describe certificate.acm.services.k8s.aws <name> -n <namespace>
```

### Check IRSA

```bash
kubectl get sa ack-acm-controller -n <namespace> -o yaml | grep eks.amazonaws.com/role-arn
```

### Common Issues

- **Certificate stuck in pending**: Check Route53 DNS validation records are created. The ACM controller needs DNS validation to complete.
- **IAM errors**: Verify the IRSA role ARN in the service account annotation matches the IAM role with ACM permissions.
- **Export failure**: The target K8s secret must exist before the controller can export. The ingress module pre-creates empty TLS secrets for this purpose.
