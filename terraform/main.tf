# pin the version of the terrform azurerm provider
# this can be updated as new versions are tested
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.35.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Get the data for the client configuration. This includes subscription information needed to create resources
data "azurerm_client_config" "current" {}

# create the resource group
resource "azurerm_resource_group" "default" {
  name     = var.name
  location = var.location
}

# call the redis module
module "redis" {
  source              = "./redis"
  name                = var.name
  resource_group_name = azurerm_resource_group.default.name
  location            = var.location
}