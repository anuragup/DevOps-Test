terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "1.38.0"
      
    }
  }
}


resource "azurerm_resource_group" "resource_gp" {
   name = "Demo"
   location = "eastus"
   tags = {
     "Owner" = "Anurati Gupta"
   }
  
}


resource "azurerm_network_security_group" "main" {
  name                = "SecurityGroup1"
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = azurerm_resource_group.resource_gp.name

  security_rule {
    name                       = "rule1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "rule2"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "WebApp-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = azurerm_resource_group.resource_gp.name

 
}

resource "azurerm_subnet" "subnets" {
  count             = 2
  name              = "subnet${count.index}"
  resource_group_name = azurerm_resource_group.resource_gp.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix    = element(var.subnet_prefixes, count.index)
}

resource "azurerm_network_interface" "nics" {
   
  count             = 2
  name              = "nic-${count.index}"
  location          = azurerm_resource_group.resource_gp.location
  resource_group_name = azurerm_resource_group.resource_gp.name

  ip_configuration {
    
    name            = "ipconfig"
    primary         = true
    subnet_id       = element(azurerm_subnet.subnets[*].id ,count.index %2)
    
    private_ip_address_allocation = "Dynamic"
   
  }
}

locals {
  vm_nics = chunklist(azurerm_network_interface.nics[*].id, 2)
}

resource "azurerm_virtual_machine" "vm" {
  count             = length(var.virtual_machine_hostnames)
  name              = element(var.virtual_machine_hostnames,count.index)
  resource_group_name = azurerm_resource_group.resource_gp.name
  location          = azurerm_resource_group.resource_gp.location
  vm_size           = "Standard_DS3_v2"
  
  network_interface_ids = [element(azurerm_network_interface.nics.*.id, count.index)]
  


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "each.value"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_storage_account" "main" {
  name                     = "demo"
  resource_group_name      = azurerm_resource_group.resource_gp.name
  location                 = azurerm_resource_group.resource_gp.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  tags = {
    environment = "Dev"
  }
}

