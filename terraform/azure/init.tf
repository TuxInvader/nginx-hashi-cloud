
provider "azurerm" {
  features {}
}

provider "time" {
}

resource "azurerm_resource_group" "resgroup" {
  name     = "${var.prefix}-resources"
  location = var.location
}

data "azurerm_subscription" "current" {
}

resource "random_password" "password" {
  length = 20
  special = true
  override_special = "_%@"
}
