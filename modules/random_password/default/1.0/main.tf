# ╔═══════════════════════════════════════════════════════════╗
# ║ Module: random_password/default/1.0                       ║
# ║                                                           ║
# ║ Spec:       var.instance.spec.<field>                     ║
# ║ Inputs:     var.inputs.<name>.<section>.<field>           ║
# ║ Schemas:    see variables.tf for full types               ║
# ║                                                           ║
# ║ Rules:                                                    ║
# ║   - lookup() for optional spec fields, NOT try()          ║
# ║   - No provider blocks — providers come from inputs     ║
# ║   - prevent_destroy on stateful resources                 ║
# ║                                                           ║
# ║ Validate: raptor module validate                          ║
# ╚═══════════════════════════════════════════════════════════╝

locals {
  spec    = lookup(var.instance, "spec", {})
  length  = lookup(local.spec, "length", 16)
  special = lookup(local.spec, "special", true)
  upper   = lookup(local.spec, "upper", true)
  numeric = lookup(local.spec, "numeric", true)
}

resource "random_password" "this" {
  length           = local.length
  special          = local.special
  upper            = local.upper
  numeric          = local.numeric
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
