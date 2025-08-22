module "random_string" {
  source = "./random-string-utility"
  
  length  = var.string_length
  special = var.include_special
  upper   = var.include_upper
  lower   = var.include_lower
  numeric = var.include_numeric
}

variable "string_length" {
  description = "Length of the random string to generate"
  type        = number
  default     = 12
}

variable "include_special" {
  description = "Include special characters"
  type        = bool
  default     = false
}

variable "include_upper" {
  description = "Include uppercase letters"
  type        = bool
  default     = true
}

variable "include_lower" {
  description = "Include lowercase letters"
  type        = bool
  default     = true
}

variable "include_numeric" {
  description = "Include numeric characters"
  type        = bool
  default     = true
}

output "generated_string" {
  description = "The generated random string"
  value       = module.random_string.result
}