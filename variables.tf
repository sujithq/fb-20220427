variable "vms" {
  type = map(object({
    size = string
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    disks = map(object({
      size                 = number
      storage_account_type = string
    }))
    ultra_ssd_enabled = bool
  }))
  description = "A Map of VM configuration settings"
  default = {
    "vm1" = {
      size = "Standard_F2"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      disks = {
        "d1" = {
          size                 = 10
          storage_account_type = "Standard_LRS"
        }
        "d2" = {
          size                 = 20
          storage_account_type = "Standard_LRS"
        }
      }
      ultra_ssd_enabled = false
    }
    "vm2" = {
      size = "Standard_F3"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }
      disks = {
        "d1" = {
          size                 = 30
          storage_account_type = "UltraSSD_LRS"
        }
      }
      ultra_ssd_enabled = true
    }
  }

}
