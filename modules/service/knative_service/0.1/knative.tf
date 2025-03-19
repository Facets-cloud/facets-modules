locals {
  resource_labels = {
    resourceType = "service"
    resourceName = var.instance_name
  }
  // Port mapping
  ports_mapping = [
    for port_key, port_value in lookup(local.runtime,"ports",{}) : {
      name          = port_value.name
      containerPort = tonumber(port_value.port)
      protocol      = port_value.protocol
      service_port  = lookup(port_value, "service_port", tonumber(port_value.port))
    }
  ]

  //Env mapping
  env_mapping = [for key, value in local.env_vars :
    {
      name      = key
      value     = value
    }
  ]
  // Image pull secret implementation
  from_artifactories      = lookup(lookup(lookup(var.inputs, "artifactories", {}), "attributes", {}), "registry_secrets_list", [])
  from_kubernetes_cluster = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "registry_secret_objects", [])
  registry_secret_objects = length(local.from_artifactories) > 0 ? local.from_artifactories : local.from_kubernetes_cluster
  imagePullSecrets_mapping = [for secret in local.registry_secret_objects: {
      name = secret.name
  }]

  // Label implementation
  merged_labels = merge(local.resource_labels,lookup(local.metadata,"labels",{}))

  // Knative service crd objects
  knative_spec = {
    spec = {
      imagePullSecrets = local.imagePullSecrets_mapping
      containers =[
        {
          image = local.image_id
          env   = local.env_mapping
          ports = local.ports_mapping
        }
      ]
    }
  }

  knative_metadata = {
      annotations = lookup(local.spec,"knative_annotation",{})
      labels = local.merged_labels
  }
  knative_values = {
    apiVersion = "serving.knative.dev/v1"
    kind        = "Service"
    metadata = {
      name      = module.name.name
      namespace = var.environment.namespace
      labels = {}
    }
    spec = {
      template = {
        metadata = local.knative_metadata
        spec     = local.knative_spec.spec
      }
    }
  }


  knative_values_yaml = yamlencode(local.knative_values)
  knative_service_helm_values = {
    anyResources = {
      knative_service = local.knative_values_yaml
    }
  }
}