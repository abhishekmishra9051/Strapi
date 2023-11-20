resource "azurerm_resource_group" "abhi_resources" {
  name     = "abhi_resources"
  location = "Central India"
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "network_abhi"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.abhi_resources.location
  resource_group_name = azurerm_resource_group.abhi_resources.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.abhi_resources.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                    = "public_ip_abhi"
  location                = azurerm_resource_group.abhi_resources.location
  resource_group_name     = azurerm_resource_group.abhi_resources.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "Dev"
  }
}


data "azurerm_public_ip" "vm_public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.abhi_resources.name
}

resource "azurerm_network_interface" "pt_network_interface" {
  name                = "nic"
  location            = azurerm_resource_group.abhi_resources.location
  resource_group_name = azurerm_resource_group.abhi_resources.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}




resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "strapi"
  resource_group_name = azurerm_resource_group.abhi_resources.name
  location            = azurerm_resource_group.abhi_resources.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  depends_on          = [azurerm_public_ip.public_ip]

  network_interface_ids = [
    azurerm_network_interface.pt_network_interface.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/am_azurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file("~/.ssh/am_azurekey")
      host        = data.azurerm_public_ip.vm_public_ip.ip_address
    }
    source      = "install.sh"
    destination = "/home/adminuser/install.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file("~/.ssh/am_azurekey")
      host        = data.azurerm_public_ip.vm_public_ip.ip_address
    }
    inline = [
      "sudo chmod +x install.sh",
      "sudo ./install.sh",
    ]

  }
}

output "public_ip_address" {
  value = data.azurerm_public_ip.vm_public_ip.ip_address

}