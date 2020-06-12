output "aks_host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_username" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.username
}

output "aks_password" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.password
}

output "aks_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate 
}

output "aks_client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate 
}

output "aks_client_key" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_key 
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
}

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.aks_user_assigned_identity.id
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_user_assigned_identity.principal_id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_user_assigned_identity.client_id
}

output "azuread_service_principal_aks_sp_object_id" {
  value = azuread_service_principal.aks_sp.object_id
}

output "oauth2" {
  value = azuread_application.aks-aad-srv.oauth2_permissions
}