provider "azurerm" {
  version = "~>2.0"
  features {
  }
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = var.rsgname
    location = var.location
    tags = var.tags
}

module "azurerm_virtual_network" {
  source      = "../modules/azurerm_virtual_network"
  tags = var.tags
  vnet_address=var.vnet_address
  rsgname = azurerm_resource_group.myterraformgroup.name
  location= azurerm_resource_group.myterraformgroup.location
  subnet_address = var.subnet_address
  count_number = var.count_number
  prefix = var.prefix
  

}

module "azure_terraform_ex1_mysql" {
  source            = "../modules/mysql"
  prefix            = var.prefix
  rg_name           = azurerm_resource_group.myterraformgroup.name
  location          = var.location
  mysql_server_user = var.mysql_server_user
  mysql_server_pass = var.mysql_server_pass
}


module "virtualmachine" {
  source      = "../modules/vm"
  rgname      = azurerm_resource_group.myterraformgroup.name
  location    = azurerm_resource_group.myterraformgroup.location
  vm_size = var.vm_size
  count_num = var.count_number
  ip_addresses = var.ip_addresses
  subnet_id   = "${module.azurerm_virtual_network.subname01}"
  tags = var.tags
  mysql_server_name       = var.mysql_server_name
  mysql_server_user       = var.mysql_server_user
  mysql_server_pass       = var.mysql_server_pass
  ssh_port                = var.ssh_port
  prefix = var.prefix
  
}

module "azure_terraform_ex1_dashboard" {
  source           = "../modules/dashboard"
  prefix           = var.prefix
  count_number     = var.count_number
  rg_name          = azurerm_resource_group.myterraformgroup.name
  email_id         = var.email_id
  vmid             = "${module.virtualmachine.vm_id}"
  storageaccid     = "${module.virtualmachine.storage_acc_id}"
  mysqlserverid    = "${module.azure_terraform_ex1_mysql.mysql_server_id}"
  lbid             = "${module.virtualmachine.lb_id}"
}
