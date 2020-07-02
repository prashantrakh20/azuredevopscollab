resource "azurerm_mysql_server" "azure_terraform_ex1_mysql_server" {
  name                = "${var.prefix}-mysqlserver001"
  location            = var.location
  resource_group_name = var.rg_name

  administrator_login          = var.mysql_server_user
  administrator_login_password = var.mysql_server_pass

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
#  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_configuration" "azure_terraform_ex1_mysql_config" {
  name                = "interactive_timeout"
  resource_group_name = azurerm_mysql_server.azure_terraform_ex1_mysql_server.resource_group_name
  server_name         = azurerm_mysql_server.azure_terraform_ex1_mysql_server.name
  value               = "300"
}

resource "azurerm_mysql_firewall_rule" "azure_terraform_ex1_mysql_server_firewall_rule" {
  name                = "AllowAll"
  resource_group_name = azurerm_mysql_server.azure_terraform_ex1_mysql_server.resource_group_name
  server_name         = azurerm_mysql_server.azure_terraform_ex1_mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_mysql_database" "azure_terraform_ex1_mysql_db" {
  name                = "${var.prefix}-mysqldb"
  resource_group_name = azurerm_mysql_server.azure_terraform_ex1_mysql_server.resource_group_name
  server_name         = azurerm_mysql_server.azure_terraform_ex1_mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
