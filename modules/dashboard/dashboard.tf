resource "azurerm_monitor_diagnostic_setting" "azure_terraform_ex1_mds_vm" {
  count              = var.count_number
  name               = "${var.prefix}-mds-vm${count.index}"
  target_resource_id = var.vmid[count.index]
  storage_account_id = var.storageaccid

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "azure_terraform_ex1_mds_lb" {
  name               = "${var.prefix}-mds-lb"
  target_resource_id = var.lbid
  storage_account_id = var.storageaccid

  log {
    category = "LoadBalancerAlertEvent"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "LoadBalancerProbeHealthStatus"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "azure_terraform_ex1_mds_mysql" {
  name               = "${var.prefix}-mds-mysqlserver"
  target_resource_id = var.mysqlserverid
  storage_account_id = var.storageaccid

  log {
    category = "MySqlAuditLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "MySqlSlowLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_action_group" "azure_terraform_ex1_mag" {
  name                = "CriticalAlertsAction"
  resource_group_name = var.rg_name
  short_name          = "p0action"

email_receiver {
    name          = "sendtoadmin"
    email_address = var.email_id
  }
}

resource "azurerm_monitor_metric_alert" "azure_terraform_ex1_mma_vm" {
  count               = var.count_number
  name                = "${var.prefix}-mma-vm${count.index}"
  resource_group_name = azurerm_monitor_action_group.azure_terraform_ex1_mag.resource_group_name
  scopes              = [var.vmid[count.index]]
  description         = "Enabling Alerts on CPU, RAM HDD and Network of the VM"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Network In Total"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 100
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Network Out Total"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 100
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Disk Read Bytes"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Disk Write Bytes"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.azure_terraform_ex1_mag.id
  }
}

/*resource "azurerm_monitor_metric_alert" "azure_terraform_ex1_mma_lb" {
  name                = var.mma_name_lb
  resource_group_name = azurerm_monitor_action_group.azure_terraform_ex1_mag.resource_group_name
  scopes              = [var.lbid]
  description         = "Enabling Alerts on LoadBalancer"

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "Data Path Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20
  }

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "Health Probe Status"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 90
  }

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "Packet Count"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 10
  }

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "SYN Count"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.azure_terraform_ex1_mag.id
  }
}*/

/*resource "azurerm_monitor_metric_alert" "azure_terraform_ex1_mma_mysql" {
  name                = var.mma_name_mysql
  resource_group_name = azurerm_monitor_action_group.azure_terraform_ex1_mag.resource_group_name
  scopes              = [var.mysqlserverid]
  description         = "Enabling Alerts on MySQL Server"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/servers"
    metric_name      = "CPU percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/servers"
    metric_name      = "Memory percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/servers"
    metric_name      = "IO percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/servers"
    metric_name      = "Storage percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/servers"
    metric_name      = "Backup Storage used"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.azure_terraform_ex1_mag.id
  }
}*/


resource "azurerm_monitor_metric_alert" "azure_terraform_ex1_mma_storageacc" {
  name                = "${var.prefix}-mma-storageacc"
  resource_group_name = azurerm_monitor_action_group.azure_terraform_ex1_mag.resource_group_name
  scopes              = [var.storageaccid]
  description         = "Action will be triggered when Transactions count is greater than 50."
    
  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 50
    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"]
    }
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.azure_terraform_ex1_mag.id
  }
}
