# app service plan host for functions
resource "azurerm_service_plan" "host" {
  name                         = var.service_plan_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  os_type                      = "Linux"
  sku_name                     = var.host_sku
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
}

resource "azurerm_application_insights" "insights" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "func" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id = azurerm_service_plan.host.id

  storage_account_name       = var.sa_name
  storage_account_access_key = var.sa_key

  https_only                  = true
  functions_extension_version = "~4"

  app_settings = var.app_settings

  site_config {
    elastic_instance_minimum = var.elastic_instance_minimum
    minimum_tls_version      = "1.2"
    http2_enabled            = true
    application_insights_key = azurerm_application_insights.insights.instrumentation_key

    application_stack {
      dotnet_version              = var.dotnet_version
      use_dotnet_isolated_runtime = true
    }
  }
}
