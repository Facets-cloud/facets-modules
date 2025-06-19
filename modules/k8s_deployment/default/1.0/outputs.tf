locals {
  output_interfaces = {}
  output_attributes = {
    name             = kubernetes_deployment_v1.this.metadata[0].name
    namespace        = kubernetes_deployment_v1.this.metadata[0].namespace
    labels           = kubernetes_deployment_v1.this.metadata[0].labels
    annotations      = kubernetes_deployment_v1.this.metadata[0].annotations
    replicas         = kubernetes_deployment_v1.this.spec[0].replicas
    selector         = kubernetes_deployment_v1.this.spec[0].selector
    uid              = kubernetes_deployment_v1.this.metadata[0].uid
    generation       = kubernetes_deployment_v1.this.metadata[0].generation
    resource_version = kubernetes_deployment_v1.this.metadata[0].resource_version
  }
}
