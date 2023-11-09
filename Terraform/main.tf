
terraform {
  required_version = ">=0.12"
}

provider "azurerm" {
  features {}
  environment     = "public"
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
}

data "azurerm_image" "packer" {
  name                = var.packer_image
  resource_group_name = var.packer_resource_group
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_security_rule" "rules" {
  for_each                    = local.rules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.network-vnet]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [var.network-subnet]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

#create network interfaces for the VM's
resource "azurerm_network_interface" "example" {
  count               = var.num_of_vms
  name                = "${var.prefix}-${count.index}-nic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    primary                       = true
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

#create a public IP for the Load Balancer
resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-lb-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
}

resource "azurerm_lb" "example" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_probe" "example" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "${var.prefix}-http-server-probe"
  port                = 8080
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "${var.prefix}-lb-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = var.num_of_vms
  network_interface_id    = azurerm_network_interface.example[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.example.id
}

resource "azurerm_availability_set" "example" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  platform_fault_domain_count = 2
}


resource "azurerm_linux_virtual_machine" "example" {
  count                           = var.num_of_vms
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = var.vm-size
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  computer_name                   = "${var.prefix}-vm-${count.index}"

  network_interface_ids = [element(azurerm_network_interface.example.*.id, count.index)]
  availability_set_id   = azurerm_availability_set.example.id

  source_image_id = data.azurerm_image.packer.id

  os_disk {
    name                 = "${var.prefix}-vm-${count.index}-os-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment  = var.environment,
    project-name = "Deploying a Webpage in Azure using Terraform"
  }
}

resource "azurerm_managed_disk" "example" {
  count                = var.num_of_vms
  name                 = "data-disk-${count.index}"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  count              = var.num_of_vms
  managed_disk_id    = azurerm_managed_disk.example.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.example.*.id[count.index]
  lun                = 10 * count.index
  caching            = "ReadWrite"
}


output "lb_url" {
  value       = "http://${azurerm_public_ip.example.ip_address}/"
  description = "The Public URL for the LB."
}

output "network_resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "network_vnet_id" {
  value = azurerm_virtual_network.example.id
}

output "network_subnet_id" {
  value = azurerm_subnet.example.id
}