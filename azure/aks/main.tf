# # Locals block for hardcoded names. 
# locals {
#     backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
#     frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
#     frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
#     http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
#     listener_name                  = "${azurerm_virtual_network.test.name}-httplstn"
#     request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"
#     app_gateway_subnet_name = "appgwsubnet"
# }

/*
 * Configure a default label to use on resources.
 * Creates a label unless one is passed via a variable, via count.
 */
module "aks_label" {
  source      = "github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=0.1.0"
  namespace   = var.app_namespace
  environment = var.app_env
  name        = var.app_name
  label_order = var.aks_label_order
}


/*
 * Recieve a resource group.
 */
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}


/*
 * Obtain environment data
 */
data "azurerm_subscription" "current" {}


/*************************************************************
 * Configure Azure AD application components to allow AD based login to Kubernetes cluster 
 */
 # AAD aks Backend App - For server component (kubernetes API) that provides user authentication.
resource "azuread_application" "aks-aad-srv" {
  name                       = "${module.aks_label.id}-aks-srv"
  homepage                   = "https://${module.aks_label.id}-aks-srv"
  identifier_uris            = ["https://${module.aks_label.id}-aks-srv"]
  reply_urls                 = ["https://${module.aks_label.id}-aks-srv"]
  type                       = "webapp/api"
  group_membership_claims    = "All"
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a"
      type = "Scope"
    }
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  required_resource_access {
    resource_app_id = "00000002-0000-0000-c000-000000000000"
    resource_access {
      id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "aks-aad-srv" {
  application_id = azuread_application.aks-aad-srv.application_id
}

resource "random_password" "aks-aad-srv" {
  length  = 32
  special = true
}

resource "azuread_application_password" "aks-aad-srv" {
  application_object_id = azuread_application.aks-aad-srv.object_id
  value                 = random_password.aks-aad-srv.result
  end_date_relative     = "87600h" #10Yrs
}

/*************************************************************
 * AAD AKS kubectl app - For kubectl CLI component that provides user authentication through CLI.
 */
resource "azuread_application" "aks-aad-cli" {
  name       = "${module.aks_label.id}-aks-cli"
  homepage   = "https://${module.aks_label.id}-aks-cli"
  reply_urls = ["https://${module.aks_label.id}-aks-cli"]
  type       = "native"
  required_resource_access {
    resource_app_id = azuread_application.aks-aad-srv.application_id
    resource_access {
      # id   = azuread_application.aks-aad-srv.oauth2_permissions.0.id
      id   = [for permission in azuread_application.aks-aad-srv.oauth2_permissions : permission.id][0]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "aks-aad-cli" {
  application_id = azuread_application.aks-aad-cli.application_id
}

/*************************************************************
 * Creates Azure AD group with access to this kubernetes cluster
 */
resource "azuread_group" "aks-aad-clusteradmins" {
  name = "${module.aks_label.id}-aks-clusteradmins"
}

/*************************************************************
 * Creates a service principal application that Kubernetes uses to interact with Azure.
 */
resource "azuread_application" "aks_sp" {
  name                       = module.aks_label.id
  homepage                   = "https://${module.aks_label.id}"
  identifier_uris            = ["https://${module.aks_label.id}"]
  reply_urls                 = ["https://${module.aks_label.id}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "aks_sp" {
  application_id = azuread_application.aks_sp.application_id
}

resource "random_password" "aks_sp_pwd" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks_sp_pwd" {
  service_principal_id = azuread_service_principal.aks_sp.id
  value                = random_password.aks_sp_pwd.result
  end_date_relative     = "87600h" #10Yrs
}

resource "azurerm_role_assignment" "subscription_to_aks_sp_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aks_sp.id

  depends_on = [
    azuread_service_principal_password.aks_sp_pwd
  ]
}

/*
 * Azure User Assigned Identity; Used to help manage resources such as Application gateway via Kubernetes.
 */
resource "azurerm_user_assigned_identity" "aks_user_assigned_identity" {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  name = "${module.aks_label.id}-identity"
}

//Give this managed identity 'Operator' role on our service pricipal.
resource "azurerm_role_assignment" "aks_sp_to_aks_uai_managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.aks_user_assigned_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azuread_service_principal.aks_sp.object_id
  depends_on           = [azuread_service_principal.aks_sp, azurerm_user_assigned_identity.aks_user_assigned_identity]
}

/*
 * Give admin consent to the application
 */
 # Before giving consent, wait. Sometimes Azure returns a 200, but not all services have access to the newly created applications/services.

resource "null_resource" "delay_before_consent" {
  count = var.automate_admin_consent ? 1 : 0

  provisioner "local-exec" {
    command = "sleep 60"
  }
  depends_on = [
    azuread_service_principal.aks-aad-srv,
    azuread_service_principal.aks-aad-cli
  ]
}

# Give admin consent - SP/az login user must be AAD admin
# Only if automate_admin_consent is set to true.

resource "null_resource" "grant_srv_admin_constent" {
  count = var.automate_admin_consent ? 1 : 0

  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.aks-aad-srv.application_id}"
  }
  depends_on = [
    null_resource.delay_before_consent
  ]
}
resource "null_resource" "grant_client_admin_constent" {
  count = var.automate_admin_consent ? 1 : 0

  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.aks-aad-cli.application_id}"
  }
  depends_on = [
    null_resource.delay_before_consent
  ]
}
resource "null_resource" "delay" {
  count = var.automate_admin_consent ? 1 : 0

  provisioner "local-exec" {
    command = "sleep 60"
  }
  depends_on = [
    null_resource.grant_srv_admin_constent,
    null_resource.grant_client_admin_constent
  ]
}

/*
 * Kubernetes cluster creation
 */
 resource "azurerm_kubernetes_cluster" "aks" {
  name                = module.aks_label.id
  location            = var.azure_region
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = module.aks_label.id

  network_profile {
    network_plugin        = var.aks_network_plugin
    network_policy        = var.aks_network_policy
    dns_service_ip        = var.aks_dns_service_ip
    docker_bridge_cidr    = var.aks_docker_bridge_cidr
    # outbound_type         = var.aks_outbound_type
    pod_cidr              = var.aks_pod_cidr
    service_cidr          = var.aks_service_cidr
    # load_balancer_profile = var.aks_load_balancer_profile
    load_balancer_sku     = var.aks_load_balancer_sku
  }

  default_node_pool {
    name                = "default"
    type                = "VirtualMachineScaleSets"
    node_count          = var.aks_node_count
    max_count           = var.aks_node_count_max
    min_count           = var.aks_node_count_min
    vm_size             = var.aks_vm_size
    os_disk_size_gb     = 30
    max_pods            = var.aks_max_pods
    vnet_subnet_id      = var.aks_vnet_subnet_id
    availability_zones  = var.aks_availability_zones
    enable_auto_scaling = var.aks_enable_auto_scaling
  }

  service_principal {
    client_id     = azuread_application.aks_sp.application_id
    client_secret = random_password.aks_sp_pwd.result
  }

  role_based_access_control {
    azure_active_directory {
      client_app_id     = azuread_application.aks-aad-cli.application_id
      server_app_id     = azuread_application.aks-aad-srv.application_id
      server_app_secret = random_password.aks-aad-srv.result
      tenant_id         = data.azurerm_subscription.current.tenant_id
    }
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = var.aks_dashboard_enabled
    }
  }

  lifecycle {
    ignore_changes = [
      tags["Name"],
    ]
  }

  depends_on = [
    azurerm_role_assignment.aks_sp_to_aks_uai_managed_identity_operator,
    azuread_service_principal_password.aks_sp_pwd
  ]
}

/*
 * Assign Azure AD group admin access to Kubernetes with RBAC. 
 */
resource "kubernetes_cluster_role_binding" "cluster_admin" {
  //Gives AD group member access to log into dashboard.
  metadata {
    name = "${module.aks_label.id}-admins"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    api_group = "rbac.authorization.k8s.io"
    name      = azuread_group.aks-aad-clusteradmins.id
  }
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "kubernetes_cluster_role_binding" "service_account" {
  //Give service account access to dashboard.
  metadata {
    name = "${module.aks_label.id}-service-account"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

/*
 * Configure AAD Pod Identity Capability
 * Enabling kubernetes/pods to interact with Azure.
 */
module "aks-aad-pod-identity" {
  # source              = "https://github.com/Wycliffe-USA/terraform-modules//azure/aks-aad-pod-identity?ref=1.0.0"
  source   = "../aks-aad-pod-identity/"

  aks_name           = azurerm_kubernetes_cluster.aks.name
  aks_resource_group = data.azurerm_resource_group.rg.name
  # aks_cluster_ca_certificate = azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate
  # aks_cluster_auth_token     = azurerm_kubernetes_cluster.aks.kube_admin_config.0.password
}