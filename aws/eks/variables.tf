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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
}

variable "default_instance_types" {
  description = "Default instance types."
  type        = list(string)
  default     = ["t3.medium"]
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
