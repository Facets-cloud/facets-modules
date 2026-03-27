# ╔═══════════════════════════════════════════════════════════╗
# ║ AUTO-GENERATED from facets.yaml — DO NOT EDIT            ║
# ║                                                          ║
# ║ Any changes will be overwritten on next mutation command. ║
# ╚═══════════════════════════════════════════════════════════╝

variable "instance" {
  type = object({
    spec = object({
      length  = optional(number)
      numeric = optional(bool)
      special = optional(bool)
      upper   = optional(bool)
    })
  })
}

variable "instance_name" {
  type = string
}

variable "environment" {
  type = any
}

variable "inputs" {
  type = object({})
}
