locals {
  spec = lookup(var.instance, "spec", {})
  alarms = lookup(local.spec, "alarms", {})
}
