variable "instance" {
  description = "Workload Identity is the recommended way to access GCP services from Kubernetes. [Read more] (https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
    })
  })
}
variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}
variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    project     = string
    namespace   = string
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    kubernetes_details = object({
      attributes = object({
        legacy_outputs = object({
          k8s_details = object({
            auth = object({
              host                   = string
              cluster_ca_certificate = string
              token                  = string
            })
          })
          gcp_cloud = object({
            project_id = string
          })
          registry_secret_objects = any
        })
      })
    })
  })
}

