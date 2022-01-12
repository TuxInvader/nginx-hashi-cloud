
provider "azurerm" {
  features {}
}

provider "time" {
}

provider "http" {
}

resource "azurerm_resource_group" "resgroup" {
  name     = "${var.prefix}-resources"
  location = var.location
}

data "azurerm_subscription" "current" {
}

data "http" "ip_address" {
  url              = "https://api.ipify.org"
  request_headers  = {
    Accept = "text/plain"
  }
}

resource "random_password" "admin" {
  length = 20
  special = true
  override_special = "_%@"
}
