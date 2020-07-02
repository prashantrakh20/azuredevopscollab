output "vnname" {
  value = azurerm_virtual_network.myvnet.name
}

output "subname01" {
  value = azurerm_subnet.myterraformsubnet.id
}

