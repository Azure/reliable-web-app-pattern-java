resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = var.resource_group
  location            = var.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group
  location            = var.location

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  size                            = var.size

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_extension_linux" {
  name                 = "vm-extension-linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings             = <<SETTINGS
    {
      "script": "${filebase64("${path.module}/scripts/jumpbox-setup-cli-tools.sh")}"
    }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "vm_extension_aad" {
  name                 = "vm-aad-extension-linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux_vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_role_assignment" "vm-admin-role" {
  scope                = azurerm_linux_virtual_machine.linux_vm.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.admin_principal_id
}
