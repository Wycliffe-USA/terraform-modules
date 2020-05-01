# Obtain subscription environment data.
data "azurerm_subscription" "current" {}

data "helm_repository" "agic_repo" {
  name = "agic_repository"
  url  = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"
}

resource "random_id" "agic" {
  byte_length = 4
}

resource "helm_release" "agic" {
  provider   = helm.aks
  name        = "${var.appgw_name}-ic-${random_id.agic.hex}"
  version     = var.agic_package_version
  repository  = data.helm_repository.agic_repo.metadata[0].url
  chart       = "ingress-azure"
  namespace   = var.namespace
  timeout     = var.helm_release_agic_timeout

  values = [<<EOF
appgw:
  name: ${var.appgw_name}
  subscriptionId: ${data.azurerm_subscription.current.subscription_id}
  resourceGroup: ${var.resource_group}
  usePrivateIP: ${var.appgw_use_private_ip}
  shared: ${var.appgw_shared}
armAuth:
  type: aadPodIdentity
  identityResourceID: ${var.armauth_identity_resource_id}
  identityClientID: ${var.armauth_identity_client_id}
rbac:
  enabled: ${var.rbac_enabled}
aksClusterConfiguration:
  apiServerAddress: ${var.aks_host}
reconcilePeriodSeconds: ${var.reconcile_period_seconds}
EOF
  ]
}