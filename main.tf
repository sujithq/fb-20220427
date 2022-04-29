terraform {
  backend "azurerm" {
  }
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = join("-", ["rg", local.name])
  location = "westeurope"
}

resource "azurerm_virtual_network" "this" {
  name                = join("-", ["vnet", local.name])
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = join("-", ["vnet", "snet", local.name])
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "this" {
  for_each            = var.vms
  name                = join("-", ["nic", each.key])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = join("-", ["nic", each.key])
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each            = var.vms
  name                = join("-", ["vm", each.key])
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = each.value.size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  dynamic "additional_capabilities" {
    for_each = each.value.ultra_ssd_enabled ? ["additional_capabilities"] : []
    content {
      ultra_ssd_enabled = true
    }
  }

}

resource "azurerm_managed_disk" "this" {
  for_each             = { for d in local.disks : join("-", [d.vm, d.disk]) => d }
  name                 = join("-", ["disk", each.value.vm, each.value.disk])
  location             = azurerm_resource_group.this.location
  create_option        = "Empty"
  disk_size_gb         = each.value.size
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = each.value.storage_account_type
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each           = { for d in local.disks : join("-", [d.vm, d.disk]) => d }
  virtual_machine_id = azurerm_linux_virtual_machine.this[each.value.vm].id
  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  lun                = 0
  caching            = "None"
}
