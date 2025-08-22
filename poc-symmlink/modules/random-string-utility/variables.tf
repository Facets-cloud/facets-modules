variable "length" {
  description = "The length of the random string"
  type        = number
  default     = 16
}

variable "special" {
  description = "Include special characters in the random string"
  type        = bool
  default     = false
}

variable "upper" {
  description = "Include uppercase letters in the random string"
  type        = bool
  default     = true
}

variable "lower" {
  description = "Include lowercase letters in the random string"
  type        = bool
  default     = true
}

variable "numeric" {
  description = "Include numeric characters in the random string"
  type        = bool
  default     = true
}