terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.56.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "codility"
  location = "West Europe"
}

# 1. Storage Account
resource "azurerm_storage_account" "upload_storage_account" {
  name                     = "uploadstorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 2. Storage Container
resource "azurerm_storage_container" "upload_container" {
  name                  = "upload-container"
  storage_account_name  = azurerm_storage_account.upload_storage_account.name
  container_access_type = "blob"
}

# 3. Service Bus Namespace
resource "azurerm_servicebus_namespace" "upload_queue_ns" {
  name                = "upload-queue-ns"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

# 4. Service Bus Queue
resource "azurerm_servicebus_queue" "upload_queue" {
  name                = "upload-queue"
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.upload_queue_ns.name
  enable_partitioning = true
}

# 5. Event Grid Event Subscription
resource "azurerm_eventgrid_event_subscription" "upload_subscription" {
  name  = "upload-event-subscription"
  scope = azurerm_storage_container.upload_container.id

  included_event_types = [
    "Microsoft.Storage.BlobCreated"
  ]

  service_bus_queue_endpoint_id = azurerm_servicebus_queue.upload_queue.id
}
