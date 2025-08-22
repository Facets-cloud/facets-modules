module "random_string" {
  source = "./random-string-utility"

  length  = var.instance.spec.string_length
  special = var.instance.spec.include_special
  upper   = var.instance.spec.include_upper
  lower   = var.instance.spec.include_lower
  numeric = var.instance.spec.include_numeric
}
