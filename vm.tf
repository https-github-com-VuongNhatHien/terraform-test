locals {
  suffix = "terraform-test"
  tags = {
    ENV = "Dev"
    CREATED_BY = "Hien Vuong"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.suffix}"
  location = "southeastasia"

  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]

  tags                 = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "subnet-${local.suffix}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"

  tags     = local.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  tags     = local.tags
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags     = local.tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh-${local.suffix}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "allow-http-${local.suffix}"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "allow-https-${local.suffix}"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

data "azurerm_platform_image" "this" {
  location            = azurerm_resource_group.this.location
  publisher           = "Canonical"
  offer               = "ubuntu-24_04-lts"
  sku                 = "server"
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-${local.suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_B2s"
  admin_username      = "hien"
  admin_password      = "Machine123!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.this.id]

  source_image_reference {
    publisher = data.azurerm_platform_image.this.publisher
    offer     = data.azurerm_platform_image.this.offer
    sku       = data.azurerm_platform_image.this.sku
    version   = "latest"
  }

  os_disk {
    name = "os-disk-${local.suffix}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags     = local.tags
}

resource "azurerm_dns_zone" "this" {
  name                = "aks-hello-world.studgart.com"
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_dns_a_record" "this" {
  name                = "@"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 3600
  records             = [azurerm_public_ip.this.ip_address]

  tags = local.tags
}