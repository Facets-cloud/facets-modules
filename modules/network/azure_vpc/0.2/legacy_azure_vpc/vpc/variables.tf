variable "cluster" {
  type = any
}

variable "cc_metadata" {
  type = any
}

variable "settings" {
  type = any
  default = {}
}

variable "instance" {
  type    = any
  default = {}
}

variable "use_existing_nat_gateways" {
  description = "Whether to use existing NAT gateways instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_nat_gateway_ids" {
  description = "List of existing NAT Gateway IDs to use"
  type        = list(string)
  default     = []
}
