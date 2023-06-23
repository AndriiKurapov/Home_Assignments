# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Get the current Azure client configuration
data "azurerm_client_config" "current" {}

# Define the resource group and location
resource "azurerm_resource_group" "Task-Group-EastUS" {
  name     = "Terraform-resource-group"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "Task-VM-WindowsServer" {
  name                = "Task-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name = azurerm_resource_group.Task-Group-EastUS.name
}

# Create a subnet
resource "azurerm_subnet" "Task-Subnet" {
  name                 = "Task-Subnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.Task-VM-WindowsServer.name
  resource_group_name  = azurerm_resource_group.Task-Group-EastUS.name
}

# Create a public IP address
resource "azurerm_public_ip" "WindowsServer-IP" {
  name                = "WindowsServer"
  location            = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name = azurerm_resource_group.Task-Group-EastUS.name
  allocation_method   = "Dynamic"
}

# Create a network security group
resource "azurerm_network_security_group" "Task-NSG" {
  name                = "Task-NSG"
  location            = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name = azurerm_resource_group.Task-Group-EastUS.name
}

# Add a rule to allow RDP traffic
resource "azurerm_network_security_rule" "Task-NSG-Rule" {
  name                        = "allow-rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Task-Group-EastUS.name
  network_security_group_name = azurerm_network_security_group.Task-NSG.name
}

# Create a virtual machine
resource "azurerm_windows_virtual_machine" "Task-VM" {
  name                  = "Task-VM"
  location              = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name   = azurerm_resource_group.Task-Group-EastUS.name
  network_interface_ids = [azurerm_network_interface.Task-VM-NIC.id]
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = random_password.Task-VM-Password.result
  custom_data           = filebase64("diskpart.ps1")
  os_disk {
    name                 = "Task-VM-Disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Generate a random password and store it in a Key Vault
resource "random_password" "Task-VM-Password" {
  length  = 16
  special = true
}

resource "azurerm_key_vault" "Task-KeyVault" {
  name                      = "TerraformTask-KeyVault"
  location                  = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name       = azurerm_resource_group.Task-Group-EastUS.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
  sku_name                  = "standard"
}

# Store the password in the Key Vault
resource "azurerm_key_vault_secret" "Task-VM-Password" {
  name         = "vm-password"
  value        = random_password.Task-VM-Password.result
  content_type = "text/plain"
  key_vault_id = azurerm_key_vault.Task-KeyVault.id
}


# Create a network interface
resource "azurerm_network_interface" "Task-VM-NIC" {
  name                = "Task-VM-NIC"
  location            = azurerm_resource_group.Task-Group-EastUS.location
  resource_group_name = azurerm_resource_group.Task-Group-EastUS.name

  ip_configuration {
    name                          = "task-ipconfig"
    subnet_id                     = azurerm_subnet.Task-Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.WindowsServer-IP.id
  }
}

data "azurerm_subscription" "current" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}

resource "azurerm_role_assignment" "key_vault" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
}

resource "azurerm_role_assignment" "key_vault1" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Contributor"
}

# Associate the security group with the network interface
resource "azurerm_network_interface_security_group_association" "Task-NSG-Assciation" {
  network_interface_id      = azurerm_network_interface.Task-VM-NIC.id
  network_security_group_id = azurerm_network_security_group.Task-NSG.id
}