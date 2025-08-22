locals {
  output_attributes = {
    generated_string = module.random_string.result
    string_length    = var.instance.spec.string_length
    includes_special = var.instance.spec.include_special
    resource_name    = var.instance_name
    resource_type    = "\"random_string_generator\""
  }
  output_interfaces = {
    string_value = {
      value                 = module.random_string.result
      length                = var.instance.spec.string_length
      special_chars_enabled = var.instance.spec.include_special
    }
  }
}