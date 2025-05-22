locals {
  data = base64encode(jsonencode({
    name = var.name
    resource_type = var.resource_type
    resource_name = var.resource_name
    key = var.key
    value = var.value
  }))
}

resource "null_resource" "generate-resource-details" {
  triggers = {
    name = var.name
    resource_type = var.resource_type
    resource_name = var.resource_name
    key = var.key
    value = var.value
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "mkdir -p resource-details; echo ${local.data} | base64 -d > resource-details/${md5(local.data)}.json"
  }
}