variable "name" {
  type        = string
  description = "the name of this deployment. used within resource names"
  nullable    = false
}

variable "location" {
  type        = string
  description = "the region location where resources are deployed"
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "the resource group name used to deploy the resources in this module"
  nullable    = false
}