data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group
}

provider "helm" {
  version = "1.1.1"
  alias = "aks"

  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
    username               = data.azurerm_kubernetes_cluster.aks.kube_config.0.username
    password               = data.azurerm_kubernetes_cluster.aks.kube_config.0.password
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
    load_config_file       = false
  }
}