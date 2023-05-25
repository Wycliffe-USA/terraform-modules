variable "app_name" {
  description = "Name of app.  Used for naming and tags."
  type        = string
}

variable "app_env" {
  description = "Environment of app.  Used for naming and tags."
  type        = string
}

################################################################################
# Cluster
################################################################################
variable "load_balancer_controller_helm_chart_version" {
  description = "Helm chart version for application-load-balancer controller"
  type        = string
  default     = "1.5.2"
}

variable "cert_manager_controller_helm_chart_version" {
  description = "Helm chart version for cert-manager"
  type        = string
  default     = "v1.11.1"
}

variable "certificate_issuer_email" {
  description = "Email address for cert-manager issued certificates"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = [ "0.0.0.0/0" ]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
  default     = "1.26"
}



variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. EKS assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks. We override this to 10.11.2.0/22."
  type        = string
  default     = "10.11.2.0/22"
}

variable "default_instance_types" {
  description = "Default instance types."
  type        = list(string)
  default     = ["t3.small"]
}

variable "enable_cert_manager_controller" {
  #Cert-Manager is usefule for end-to-end encryption, but cannot produce public certificates via Let's Encrypt because EKS cluster's don't support this.
  #This is why it's disabled by default.
  description = "Install cert-manager into the Kubernetes cluster"
  type        = bool
  default     = false
}

variable "enable_load_balancer_controller" {
  description = "Install load-balancer into the Kubernetes cluster"
  type        = bool
  default     = true
}

variable "system_instance_types" {
  description = "System instance types."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "workload_instance_types" {
  description = "System instance types."
  type        = list(string)
  default     = []
}

variable "control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane."
  type        = list(string)
  default     = []
}

variable "node_group_default_max_size" {
  description = "Maximum size of the default node group."
  type        = number
  default     = 3
}

variable "node_group_default_min_size" {
  description = "Minimum size of the default node group."
  type        = number
  default     = 1
}

variable "node_group_default_desired_size" {
  description = "Desired size of the default node group."
  type        = number
  default     = 2
}

variable "node_group_system_max_size" {
  description = "Maximum size of the system node group."
  type        = number
  default     = 2
}

variable "node_group_system_min_size" {
  description = "Minimum size of the system node group."
  type        = number
  default     = 1
}

variable "node_group_system_desired_size" {
  description = "Desired size of the system node group."
  type        = number
  default     = 1
}

variable "node_group_workload_max_size" {
  description = "Maximum size of the workload node group."
  type        = number
  default     = null
}

variable "node_group_workload_min_size" {
  description = "Minimum size of the workload node group."
  type        = number
  default     = null
}

variable "node_group_workload_desired_size" {
  description = "Desired size of the workload node group."
  type        = number
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs to place Kubernetes nodes into."
  type        = list(string)
}

variable "tags" {
  description = "Map of additional tags to pass to this module."
  type        = map(any)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC for the cluster."
  type        = string
}

variable "aws_region" {
  description = "The aws_region."
  type        = string
}