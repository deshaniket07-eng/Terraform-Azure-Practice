# vm.tf - adds VNet, Subnet, NSG, Public IP, NIC and a Linux VM

resource "random_integer" "vm_suffix" {
  min = 10000
  max = 99999
}

# Virtual Network (if not already created)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terraform-demo"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group to allow SSH (lock down as needed)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-terraform-vm"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "74.234.218.204"      
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "Allow-ICMP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"   # VERY IMPORTANT
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

# Public IP for the VM
resource "azurerm_public_ip" "pip" {
  name                = "pip-vm-${random_integer.vm_suffix.result}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface - attach pip and subnet
resource "azurerm_network_interface" "nic" {
  name                = "nic-vm-${random_integer.vm_suffix.result}"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-terraform-demo-${random_integer.vm_suffix.result}"
  resource_group_name = var.rg_name
  location            = var.location
  size                = "Standard_B1s"         
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/deshpani/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    environment = "dev"
    owner       = "Aniket"
  }

}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

