output "tls_private_key" { 
  value = tls_private_key.example_ssh.private_key_pem
}

output "vm_id" {
//  value = element(azurerm_linux_virtual_machine.azure_terraform_ex1_vm.*.id, count.index)
  value = azurerm_linux_virtual_machine.myterraformvm[*].id
}

output "storage_acc_id" {
  value = azurerm_storage_account.mystorageaccount.id
}

output "lb_id" {
  value = azurerm_lb.azurelb.id
}