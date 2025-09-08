module "helm_history_workflow" {
  source = "github.com/Facets-cloud/facets-utility-modules//actions/kubernetes?ref=workflows"
  name   = "helm-history"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = helm.release-pod
  }

  description = "Retrieves helm release history for the deployed chart"
  steps = [
    {
      name      = "get-helm-history"
      image     = "alpine/helm:latest"
      resources = {}
      env       = []
      script    = <<-EOT
        #!/bin/bash
        echo "Fetching helm history for release: ${helm_release.external_helm_charts.name}"
        helm history ${helm_release.external_helm_charts.name} -n ${helm_release.external_helm_charts.namespace}
      EOT
    }
  ]
}

module "helm_rollback_workflow" {
  source = "github.com/Facets-cloud/facets-utility-modules//actions/kubernetes?ref=workflows"
  name   = "helm-rollback"

  instance_name    = var.instance_name
  environment      = var.environment
  instance         = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = helm.release-pod
  }

  description = "Rolls back helm release to a specified revision"
  params = [
    {
      name        = "revision"
      description = "Revision number to rollback to"
      default = "1"
    }
  ]
  steps = [
    {
      name      = "rollback-helm-release"
      image     = "alpine/helm:latest"
      resources = {}
      env       = []
      script    = <<-EOT
        #!/bin/bash
        REVISION="$(params.revision)"
        
        if [ -z "$REVISION" ]; then
          echo "error: Revision number is required"
          exit 1
        fi
        
        echo "Rolling back release ${helm_release.external_helm_charts.name} to revision $REVISION"
        helm rollback ${helm_release.external_helm_charts.name} $REVISION -n ${helm_release.external_helm_charts.namespace}
        
        if [ $? -eq 0 ]; then
          echo "Rollback successful"
          echo "Current release status:"
          helm status ${helm_release.external_helm_charts.name} -n ${helm_release.external_helm_charts.namespace}
        else
          echo "Rollback failed"
          exit 1
        fi
      EOT
    }
  ]
}