# variable "aks_host" {
#   description = "AKS Cluster host"
# }

# variable "aks_cluster_ca_certificate" {
#   description = "Cluster CA Certificate from AKS Cluster."
# }

# variable "aks_cluster_auth_token" {
#   description = "Cluster Auth Token from AKS Cluster."
# }

variable "aks_name" {
  description = "AKS Cluster name"
}

variable "aks_resource_group" {
  description = "Resource group of aks cluster."
}