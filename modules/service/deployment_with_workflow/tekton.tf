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

  steps = {
    "restart-deployments" = {
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
  }
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

  params = {
    "ACTION" = {
      name        = "ACTION"
      type        = "string"
      description = "supported actions: restart, stop, start"
      default     = "restart"
    }
    "flags" = {
      name        = "flags"
      type        = "array"
      description = "array of compilation flags or options"
      default     = ["--verbose", "--force"]
    }
    "gitrepo" = {
      name        = "gitrepo"
      type        = "object"
      description = "git repository information with url and commit"
      properties = {
        url = {
          type = "string"
        }
        commit = {
          type = "string"
        }
      }
    }
    "timeout" = {
      name        = "timeout"
      type        = "string"
      description = "timeout duration in Go format (e.g., 30s, 5m, 1h)"
      default     = "300s"
    }
    "debug" = {
      name        = "debug"
      type        = "string"
      description = "enable debug mode (true/false)"
      default     = "false"
    }
  }

  steps = {
    "print-params" = {
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
  }
}