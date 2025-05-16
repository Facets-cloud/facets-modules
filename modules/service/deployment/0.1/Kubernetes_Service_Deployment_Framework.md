# Kubernetes Service Deployment Framework

## Overview

This framework provides a standardized approach for deploying and managing services across multiple cloud environments (AWS, Azure, GCP) and Kubernetes clusters. The service module supports a variety of deployment configurations, making it easy to customize your service deployments with best practices built in.

### Key Features

- Multi-cloud compatibility (AWS, Azure, GCP, and Kubernetes)  
- Robust container lifecycle management  
- Flexible resource allocation  
- Built-in health checks and probes  
- Autoscaling capabilities  
- Comprehensive volume management  
- Support for init containers and sidecars  
- Cloud-specific IAM and permissions management  

## Configurability

The framework offers extensive configuration options for your service deployments.

### Basic Configuration

- **Namespace management**: Deploy to specific Kubernetes namespaces  
- **Service type**: Define application deployment type  
- **Restart policy**: Configure container restart behavior (Always, OnFailure, Never)  
- **Host anti-affinity**: Distribute pods across different physical hosts  

### Runtime Configuration

- **Container resources**: Specify CPU and memory requests/limits  
- **Port mapping**: Configure container and service ports with protocol settings  
- **Health checks**: Set up readiness and liveness probes with HTTP, port, or exec checks  
- **Autoscaling**: Configure min/max replicas with CPU or RAM-based scaling  
- **Metrics**: Define metrics endpoints for monitoring  
- **Volumes**: Mount various volume types (ConfigMaps, Secrets, PVCs, HostPath)  

### Deployment Management

- **Image configuration**: Specify container images and pull policies  
- **Deployment strategy**: Configure RollingUpdate or Recreate strategies  
- **Disruption policies**: Set minimum availability during updates  

### Advanced Features

- **Init containers**: Configure containers that run before application containers  
- **Sidecars**: Set up auxiliary containers that run alongside your main container  
- **Cloud permissions**: Configure cloud-specific IAM roles and policies:
  - **AWS**: IAM policies with IRSA support  
  - **GCP**: Role-based access with conditional expressions  
  - **Azure**: Role assignments  

## Usage

The service module is configured using a YAML definition file that follows a standardized schema. The schema provides structured fields for all aspects of the service deployment.

### How to Use the Framework

1. **Service Definition**: Create a YAML configuration file that defines your service properties according to the schema.  
2. **Environment Configuration**: Specify cloud-specific settings depending on your target environment (AWS, Azure, GCP, or Kubernetes).  
3. **Resource Allocation**: Define CPU, memory, and scaling parameters based on application requirements.  
4. **Deployment Configuration**: Set up strategies for updates, health checks, and container lifecycle.  
5. **Optional Features**: Configure additional capabilities like init containers, sidecars, and cloud permissions as needed.  

The framework handles the generation of appropriate Kubernetes manifests based on your configuration, ensuring consistency across environments while adhering to cloud-specific best practices.

Refer to the schema documentation for complete details on all available configuration options.
