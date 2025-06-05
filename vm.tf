locals {
  suffix = "terraform-test"
}
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.suffix}"
  location = "southeastasia"
}