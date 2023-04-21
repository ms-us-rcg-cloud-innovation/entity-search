variable "resource_group_name" {
  type = string
}

variable "service_plan_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_name" {
  type = string
}

variable "host_sku" {
  type = string
  default = "EP1"
}

variable "app_settings" {
    type    = map(string)
    default = null
}

variable "sa_name" {
  type = string
}

variable "sa_key" {
  type = string
}

variable "dotnet_version" {
  type = string
  default = "6.0"
}

variable "maximum_elastic_worker_count" {
  type = number
  default = 3
}

variable "elastic_instance_minimum" {
  type = number
  default = 3 
}
