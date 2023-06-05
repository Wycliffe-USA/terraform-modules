variable "repo_name" {
  type = string
}

variable "ecsServiceRole_arn" {
  type = string
}

variable "ecsInstanceRole_arn" {
  type = string
}

variable "cd_user_arn" {
  type = string
}

variable "image_retention_count" {
  default = 25
}

variable "image_retention_tags" {
  type    = list(string)
  default = ["latest"]
}

variable "vars" {
  description = "Additional tags to add to resources created by this module."
  type        = map(any)
  default     = {}
}