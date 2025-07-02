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

variable "instance_name" {
  description = "Name of the instance for resource naming"
  type        = string
}

variable "nat_gateway_type" {
  description = "Type of NAT gateway configuration: create_new or use_existing. Note: NAT gateways cannot be shared across different Virtual Networks"
  type        = string
  default     = "create_new"
}

variable "existing_nat_gateway_name" {
  description = "Name of existing NAT gateway. Note: NAT gateway cannot be already associated with subnets in a different VNet"
  type        = string
  default     = ""
}

variable "use_vnet_resource_group" {
  description = "Whether to use VNet's resource group for existing NAT gateway lookup"
  type        = bool
  default     = true
}

variable "existing_nat_gateway_resource_group" {
  description = "Resource group name where existing NAT gateways are located"
  type        = string
  default     = ""
}
