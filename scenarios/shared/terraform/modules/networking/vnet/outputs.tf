// ------------------
// OUTPUTS
// ------------------

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnets" {
  value = { for subnet in azurerm_subnet.this : subnet.name => subnet }
}