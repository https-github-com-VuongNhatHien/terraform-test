terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.31.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "rg-storage-terraform-test"
      storage_account_name = "hienteststorageterraform"
      container_name       = "container-terraform-test"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}