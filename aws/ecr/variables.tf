variable "repo_name" {
  type = string
}

variable "ecs_service_role_arn" {
  type = string
  default = ""
}

variable "ecs_instance_role_arn" {
  type = string
  default = ""
}

variable "eks_cluster_role_arn" {
  type = string
  default = ""
}

variable "image_retention_count" {
  default = 25
}

variable "image_retention_tags" {
  type    = list(string)
  default = ["latest"]
}

variable "tags" {
  description = "Additional tags to add to resources created by this module."
  type        = map(any)
  default     = {}
}