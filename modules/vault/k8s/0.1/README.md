Vault (Kubernetes Flavor)
=========================

Overview
--------

This module provisions a HashiCorp Vault cluster on Kubernetes using Facets infrastructure automation. It enables teams to securely manage secrets, encryption keys, and access controls for cloud-native workloads. The Vault instances are deployed via Helm charts and support standalone or HA (high availability) modes depending on the instance count.

This Kubernetes flavor of the Vault module is designed to be cloud-agnostic and works across AWS, Azure, GCP, and Kubernetes environments. It includes lifecycle automation to initialize Vault, unseal it, and persist the root token as a Kubernetes secret.

Configurability
---------------

Configuration options are available through the advanced.k8s.vault block. Key options include:

*   **vault\_version**: The Vault version to deploy (e.g., "1.17.2").
    
*   **size**:
    
    *   **instance\_count**: Number of Vault instances to deploy (1–10).
        
    *   **cpu**: CPU request for each instance (e.g., "250m").
        
    *   **cpu\_limit**: CPU limit for each instance (e.g., "500m").
        
    *   **memory**: Memory request (e.g., "256Mi").
        
    *   **memory\_limit**: Memory limit (e.g., "512Mi").
        
    *   **volume**: Persistent volume size (e.g., "10Gi").
        

Other advanced options such as Helm chart version, timeouts, and custom Helm values can be passed via the advanced.k8s.vault.values block.

The module also includes lifecycle logic to:

*   Automatically initialize Vault after pod readiness.
    
*   Unseal Vault using generated keys.
    
*   Store the root token securely in a Kubernetes secret.
    

Usage
-----

This module can be used to deploy Vault in Kubernetes for secure secret storage, identity-based access, and encryption workflows. It supports:

*   **Standalone mode** (when instance\_count is 1)
    
*   **HA mode with Raft** (when instance\_count > 1)
    

Typical use cases include:

*   Managing secrets for applications running in Kubernetes
    
*   Dynamic secrets provisioning for cloud resources (databases, IAM)
    
*   Encryption-as-a-Service using Vault's transit engine
    
*   Centralized credential lifecycle and rotation management
    

Once deployed, Vault becomes accessible internally via the service name and exposes port 8200 for API and CLI interaction. The root token is saved as a Kubernetes secret and can be retrieved securely.
