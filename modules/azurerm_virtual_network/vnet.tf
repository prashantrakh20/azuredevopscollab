# Create virtual network
resource "azurerm_virtual_network" "myvnet" {
    # name                = "myVnet"
    name                = "${var.prefix}-network"
    address_space       = [var.vnet_address]
    location            = var.location
    resource_group_name = var.rsgname
    tags = var.tags
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = var.rsgname
    virtual_network_name = azurerm_virtual_network.myvnet.name
    address_prefixes     = [var.subnet_address]

    
    }


