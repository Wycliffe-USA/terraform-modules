variable "app_name" {
  description = "Name of app.  Used for naming and tags."
  type        = string
}

variable "app_env" {
  description = "Environment of app.  Used for naming and tags."
  type        = string
}

variable "chart_version" {
  description = "Helm Chart Version for AWS Load Balancer Controller."
  type        = string
  default     = "1.5.2"
}


variable "cluster_name" {
  description = "EKS cluster name.  Usually derived from module.eks.cluster_name"
  type        = string
}

variable "aws_iam_oidc_provider_arn" {
  description = "Open ID Connect provider ARN from EKS Cluster IAM."
  type        = string
}

variable "tags" {
  description = "Map of additional tags to pass to this module."
  type        = map(any)
  default     = {}
}