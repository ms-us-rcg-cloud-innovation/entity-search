# this random string is used to get a unique redis account name
resource "random_string" "redis" {
  length  = 5
  special = false
  upper   = false
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "redis" {
  name                = "redis-${var.name}-${random_string.redis.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}