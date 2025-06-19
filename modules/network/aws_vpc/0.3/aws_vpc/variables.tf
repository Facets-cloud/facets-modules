variable "cluster" {
  type = any
}

variable "instance" {
  type = any
}

variable "instance_name" {
  type = any
}

variable "cc_metadata" {
  type = any
}

variable "settings" {
  type    = any
  default = {}
}

variable "include_cluster_code" {
  type = bool
  default = false
}

variable "use_existing_nat_gateways" {
  description = "Whether to use existing NAT gateways instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_nat_gateway_ids" {
  description = "List of existing NAT gateway IDs to use instead of creating new ones"
  type        = list(string)
  default     = []
}
