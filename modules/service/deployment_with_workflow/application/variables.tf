variable "namespace" {
  type = string
}

variable "chart_name" {
  type = string
}

variable "values" {
  type = any
}

variable "annotations" {
  type = any
}

variable "labels" {
  type = any
}

variable "registry_secret_objects" {
  type = any
}

variable "cc_metadata" {
  type = any
}

variable "baseinfra" {
  type = any
}

variable "cluster" {
  type = any
}

variable "environment" {
  
}

variable "inputs" {
  type = any
}

variable "vpa_release_id" {
  type = string
}