variable "app_namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "app_env" {
  type        = string
  default     = "prod"
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'test'"
}

variable "app_name" {
  type        = string
  description = "Name of this application. Alternatively, the primary name used in naming resources in this configuration."
}

variable "azure_client_id" {
  type        = string
  description = "Azure client ID for terraform access"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret for terraform access"
}

# variable "azure_subscription_id" {
#   type        = string
#   description = "Azure subscription id"
# }

# variable "azure_tenant_id" {
#   type        = string
#   description = "Azure tenant id"
# }

variable "azure_region" {
  type        = string
  description = "Azure Region"
}

variable "automate_admin_consent" {
  type        = bool
  default     = false
  description = "If true passes az commands to the local interpreter to automate admin consent.  Otherwise do this manually during setup."
}

variable "aks_availability_zones" {
  type        = list
  default     = [1, 2, 3]
  description = "A list of Availability Zones across which the Node Pool should be spread. Pass null for no preference."
}

variable "aks_enable_auto_scaling" {
  type        = bool
  default     = false
  description = "Should the Kubernetes Auto Scaler be enabled for this Node Pool?"
}

variable "aks_dashboard_enabled" {
  type        = bool
  default     = false
  description = "Enable the Kubernetes dashboard to run on the cluster."
}

variable "resource_group_name" {
  description = "The resource group name to be imported"
}

variable "aks_label_order" {
  type = list(string)
  default = ["namespace", "name", "component", "environment", "stage", "attributes"]
  description = "label order for null-label label_default"
}

variable "aks_label_tags" {
  type        = map(string)
  default     = {}
}

variable "aks_dns_service_ip" {
  type        = string
  default     = "10.11.4.2"
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery"
}

variable "aks_docker_bridge_cidr" {
  type         = string
  default     = "10.11.0.1/26"
  description = "Docker0 subnet on hosts. Rarely used by docker service/pods, except for during docker build commands."
}

variable "aks_service_cidr" {
  type        = string
  default     = "10.11.4.0/22"
  description = "This is the set of virtual IPs that Kubernetes assigns to internal services in your cluster. https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni"
}

variable "aks_load_balancer_sku" {
  type    = string
  default = "Standard"
}

variable "aks_load_balancer_profile" {
  type    = string
  default = null
}

variable "aks_max_pods" {
  type    = string
  default = 110
}

variable "aks_network_plugin" {
  type    = string
  default = "azure"
}

variable "aks_network_policy" {
  type    = string
  default = "azure"
}

variable "aks_node_count" {
  type    = string
  default = "3"
}

variable "aks_node_count_min" {
  type    = string
  default = null
}

variable "aks_node_count_max" {
  type    = string
  default = null
}

variable "aks_outbound_type" {
  type    = string
  default = "loadBalancer"
}

variable "aks_pod_cidr" {
  type    = string
  default = null
}

variable "aks_vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Azure VM size."
}

variable "aks_vnet_subnet_id" {
  type         = string
  default      = null
  description = "The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
}