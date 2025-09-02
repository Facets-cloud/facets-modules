module "rollout_restart_task" {
  source = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/kubernetes?ref=workflows"
  name   = "rollout-restart"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = "helm.release-pod"
  }

  description = "This task performs a rollout restart of Kubernetes deployments based on labels."
  steps = [
    {
      name      = "restart-deployments"
      image     = "bitnami/kubectl:latest"
      resources = {}
      env = [
        {
          name  = "RESOURCE_TYPE"
          value = local.resource_type
        },
        {
          name  = "RESOURCE_NAME"
          value = local.resource_name
        },
        {
          name  = "NAMESPACE"
          value = local.namespace
        }
      ]
      script = <<-EOT
        #!/bin/bash
        set -e
        echo "Starting Kubernetes deployment rollout restart workflow..."
        echo "Resource Type: $RESOURCE_TYPE"
        echo "Resource Name: $RESOURCE_NAME"
        
        # Define label selector
        LABEL_SELECTOR="resourceType=$RESOURCE_TYPE,resourceName=$RESOURCE_NAME"
        echo "Label selector: $LABEL_SELECTOR"
        
        # Find deployments with matching labels
        DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -l "$LABEL_SELECTOR" -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
        
        if [ -z "$DEPLOYMENTS" ]; then
          echo "No deployments found with labels: $LABEL_SELECTOR"
          exit 0
        fi
        
        echo "Found deployments:"
        echo "$DEPLOYMENTS"
        
        echo "Performing rollout restart for deployments..."
        while IFS= read -r deployment; do
          if [ -n "$deployment" ]; then
            namespace=$NAMESPACE
            name=$(echo "$deployment" | cut -d'/' -f2)
            echo "Restarting deployment: $name in namespace: $namespace"
            
            kubectl rollout restart deployment "$name" -n "$namespace"
            if [ $? -eq 0 ]; then
              echo "Rollout restart initiated for $name"
              echo "Waiting for rollout to complete..."
              kubectl rollout status deployment "$name" -n "$namespace" --timeout=300s
              if [ $? -eq 0 ]; then
                echo "Rollout completed successfully for $name"
              else
                echo "Rollout timeout or failed for $name"
                exit 1
              fi
            else
              echo "Failed to initiate rollout restart for $name"
              exit 1
            fi
          fi
        done <<< "$DEPLOYMENTS"
        echo "All deployments restarted successfully."
      EOT
    }
  ]
}

module "print_params_task" {
  source = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/kubernetes?ref=workflows"
  name   = "print-params"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = "helm.release-pod"
  }

  description = "This task prints the parameters passed to the workflow."
  params = [
    {
      name        = "ACTION"
      type        = "string"
      description = "supported actions: restart, stop, start"
      default     = "restart"
    },
    {
      name        = "flags"
      type        = "array"
      description = "array of compilation flags or options"
      default     = ["--verbose", "--force"]
    },
    {
      name        = "timeout"
      type        = "string"
      description = "timeout duration in Go format (e.g., 30s, 5m, 1h)"
      default     = "300s"
    },
    {
      name        = "debug"
      type        = "string"
      description = "enable debug mode (true/false)"
      default     = "false"
    }
  ]

  steps = [
    {
      name      = "print-params"
      image     = "bitnami/kubectl:latest"
      resources = {}
      env = [
        {
          name  = "RESOURCE_TYPE"
          value = local.resource_type
        },
        {
          name  = "RESOURCE_NAME"
          value = local.resource_name
        },
        {
          name  = "NAMESPACE"
          value = local.namespace
        }
      ]
      script = <<-EOT
        #!/bin/bash
        set -e
        
        echo "Task completed successfully!"
      EOT
    }
  ]
}


module "scale_down_task" {
  source = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/kubernetes?ref=workflows"
  name   = "scale-down"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = "helm.release-pod"
  }

  description = "This task scales down Kubernetes serive to 0 replicas based on labels."
  steps = [
    {
      name      = "scale-down-service"
      image     = "bitnami/kubectl:latest"
      resources = {}
      env = [
        {
          name  = "RESOURCE_TYPE"
          value = local.resource_type
        },
        {
          name  = "RESOURCE_NAME"
          value = local.resource_name
        },
        {
          name  = "NAMESPACE"
          value = local.namespace
        }
      ]
      script = <<-EOT
        #!/bin/bash
        set -e
        echo "Starting Kubernetes deployment scale down workflow..."
        echo "Resource Type: $RESOURCE_TYPE"
        echo "Resource Name: $RESOURCE_NAME"
        
        # Define label selector
        LABEL_SELECTOR="resourceType=$RESOURCE_TYPE,resourceName=$RESOURCE_NAME"
        echo "Label selector: $LABEL_SELECTOR"
        
        # Find deployments with matching labels
        DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -l "$LABEL_SELECTOR" -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
        
        if [ -z "$DEPLOYMENTS" ]; then
          echo "No deployments found with labels: $LABEL_SELECTOR"
          exit 0
        fi
        
        echo "Found deployments:"
        echo "$DEPLOYMENTS"
        
        echo "Scaling down deployments to 0 replicas..."
        while IFS= read -r deployment; do
          if [ -n "$deployment" ]; then
            namespace=$NAMESPACE
            name=$(echo "$deployment" | cut -d'/' -f2)
            echo "Processing deployment: $name in namespace: $namespace"
            
            # Get current replica count
            CURRENT_REPLICAS=$(kubectl get deployment "$name" -n "$namespace" -o jsonpath='{.spec.replicas}')
            echo "Current replicas for $name: $CURRENT_REPLICAS"
            
            # Store original replica count as annotation
            kubectl annotate deployment "$name" -n "$namespace" "workflow.facets.cloud/original-replicas=$CURRENT_REPLICAS" --overwrite
            if [ $? -eq 0 ]; then
              echo "Stored original replica count ($CURRENT_REPLICAS) for $name"
            else
              echo "Failed to store original replica count for $name"
              exit 1
            fi
            
            # Scale down to 0 replicas
            kubectl scale deployment "$name" -n "$namespace" --replicas=0
            if [ $? -eq 0 ]; then
              echo "Deployment $name scaled down to 0 replicas"
            else
              echo "Failed to scale down deployment $name"
              exit 1
            fi
          fi
        done <<< "$DEPLOYMENTS"
        echo "All deployments scaled down successfully."
      EOT
    }
  ]
}


module "scale_up_task" {
  source = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/kubernetes?ref=workflows"
  name   = "scale-up"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = "helm.release-pod"
  }

  description = "This task scales up Kubernetes deployments to their original replica count based on stored annotation."
  steps = [
    {
      name      = "scale-up-deployments"
      image     = "bitnami/kubectl:latest"
      resources = {}
      env = [
        {
          name  = "RESOURCE_TYPE"
          value = local.resource_type
        },
        {
          name  = "RESOURCE_NAME"
          value = local.resource_name
        },
        {
          name  = "NAMESPACE"
          value = local.namespace
        }
      ]
      script = <<-EOT
        #!/bin/bash
        set -e
        echo "Starting Kubernetes deployment scale up workflow..."
        echo "Resource Type: $RESOURCE_TYPE"
        echo "Resource Name: $RESOURCE_NAME"
        
        # Define label selector
        LABEL_SELECTOR="resourceType=$RESOURCE_TYPE,resourceName=$RESOURCE_NAME"
        echo "Label selector: $LABEL_SELECTOR"
        
        # Find deployments with matching labels
        DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -l "$LABEL_SELECTOR" -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
        
        if [ -z "$DEPLOYMENTS" ]; then
          echo "No deployments found with labels: $LABEL_SELECTOR"
          exit 0
        fi
        
        echo "Found deployments:"
        echo "$DEPLOYMENTS"
        
        echo "Scaling up deployments to original replica count..."
        while IFS= read -r deployment; do
          if [ -n "$deployment" ]; then
            namespace=$NAMESPACE
            name=$(echo "$deployment" | cut -d'/' -f2)
            echo "Processing deployment: $name in namespace: $namespace"
            
            # Get original replica count from annotation
            ORIGINAL_REPLICAS=$(kubectl get deployment "$name" -n "$namespace" -o jsonpath='{.metadata.annotations.workflow\.facets\.cloud/original-replicas}')
            
            if [ -z "$ORIGINAL_REPLICAS" ]; then
              echo "No original replica count annotation found for $name. Skipping scale up - don't know what count to scale up to."
              continue
            fi
            
            echo "Original replicas for $name: $ORIGINAL_REPLICAS"
            
            # Scale up to original replica count
            kubectl scale deployment "$name" -n "$namespace" --replicas="$ORIGINAL_REPLICAS"
            if [ $? -eq 0 ]; then
              echo "Deployment $name scaled up to $ORIGINAL_REPLICAS replicas"
              
              # Remove the annotation after successful scale up
              kubectl annotate deployment "$name" -n "$namespace" "workflow.facets.cloud/original-replicas-"
              if [ $? -eq 0 ]; then
                echo "Removed original replica count annotation for $name"
              else
                echo "Warning: Failed to remove original replica count annotation for $name"
              fi
            else
              echo "Failed to scale up deployment $name"
              exit 1
            fi
          fi
        done <<< "$DEPLOYMENTS"
        echo "All deployments scaled up successfully."
      EOT
    }
  ]
}

