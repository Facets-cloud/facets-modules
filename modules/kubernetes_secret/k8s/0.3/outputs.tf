locals {
  output_attributes = {
    name = lower(var.instance_name)
    hash = md5(jsonencode(merge(lookup(local.spec, "data", {}), lookup(local.spec, "json_data", {}))))
  }

  output_interfaces = {}
}
