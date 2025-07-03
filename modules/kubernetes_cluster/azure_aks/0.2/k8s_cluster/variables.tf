variable "vpc_details" {
  description = "VPC details including region and other network information"
  type = object({
    region = string
  })
}

variable "instance" {
  description = "A Kubernetes EKS cluster module with auto mode enabled by default and all necessary configurations preset."
  type = any
}

variable "cluster" {
  description = "cluster object configuration"
  type = any
  default = {}
}

variable "cc_metadata" {
  description = "cc_metadata object configuration"
  type = any
}

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string

}

variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
}

variable "vpc_id" {
  description = "The VPC ID for the cluster."
  type        = string
}

variable "k8s_subnets" {
  description = "The subnets for the cluster."
  type        = list(string)
}

variable "region" {
  description = "The AZURE region where the cluster is deployed."
  type        = string
}

variable "resource_group_name" {
  description = "value for the resource group name where the cluster is deployed."
  type        = string
}

variable "azs" {
  description = "The availability zones for the cluster."
  type        = list(string)
}

variable "private_subnets" {
  description = "value for the private subnets where the cluster is deployed."
  type        = list(string)
}

variable "public_subnets" {
  description = "value for the public subnets where the cluster is deployed."
  type        = list(string)
}