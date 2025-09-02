module "helm_history_workflow" {
  source = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/kubernetes?ref=workflows"
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