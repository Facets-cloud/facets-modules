resource "random_string" "this" {
  length  = var.length
  special = var.special
  upper   = var.upper
  lower   = var.lower
  numeric = var.numeric
}