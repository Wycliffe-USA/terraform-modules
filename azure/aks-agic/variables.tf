variable "agic_package_version" {
  default = "1.2.0"
}

variable "helm_release_agic_timeout" {
  default = 300
}

variable "appgw_name" {
  description = "Name of the application gateway."
}

variable "resource_group" {
  description = "Azure resource group name to place resources into."
}

variable "appgw_use_private_ip" {
  description = "Whether to use a private IP."
  default     = false
}

variable "appgw_shared" {
  description = "true will create an AzureIngressProhibitedTarget CRD. This prohibits AGIC from applying config for any host/path."
  default     = false
}

variable "armauth_identity_resource_id" {
  description = "User Assigned Identity Resource id"
}

variable "armauth_identity_client_id" {
  description = "User Assigned Identity Clienbt id"
}

variable "rbac_enabled" {
  description = "rbac enabled"
  default     = true
}

variable "reconcile_period_seconds" {
  description = "Reconcile period is time period after which AGIC will re-configure Application Gateway if the current state differs from the expected state."
  default     = 60
}

variable "namespace" {
  description = "Namespace to place the agic components into."
  default     = "default"
}

variable "aks_host" {
  description = "AKS Host."
}

variable "aks_name" {
  description = "AKS Cluster name"
}

variable "aks_resource_group" {
  description = "Resource group of aks cluster."
}