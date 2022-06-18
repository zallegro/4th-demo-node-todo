# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 0.14.9"
}
provider "azurerm" {
  features {}
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "node-todo-25876"
  location = "canadacentral"
}
# Create the Linux App Service Plan
resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "node-todo-25876"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true # Must be true for Linux plans

  sku {
    tier = "Free"
    size = "F1"
  }
}

# Create the mongodb
resource "azurerm_cosmosdb_account" "db" {
  name                = "node-todo-cosmosdb-mongo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true
  mongo_server_version= "4.0"

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level  = "Eventual"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}


# Create the web app, pass in the App Service Plan ID, and deploy code from a public GitHub repo
resource "azurerm_app_service" "webapp" {
  name                = "node-todo-25876"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  
  site_config {
    # Free tier only supports 32-bit
    use_32_bit_worker_process = true
    # Run "az webapp list-runtimes --linux" for current supported values, but
    # always connect to the runtime with "az webapp ssh" or output the value
    # of process.version from a running app because you might not get the
    # version you expect
    linux_fx_version = "NODE|10-lts"
  }

  app_settings = {
    
    MONGO_URL = azurerm_cosmosdb_account.db.connection_strings[0]
  }

  depends_on = [azurerm_cosmosdb_account.db]


}