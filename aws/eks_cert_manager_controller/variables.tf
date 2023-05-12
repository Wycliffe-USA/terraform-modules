## Cert-Manager
variable "certificate_issuer_email" {
  description = "Email address used for certificate ACME registration."
  type        = string
}

variable "chart_version" {
  description = "Version of Chart to install/upgrade."
  type        = string
  default     = "v1.11.1"
}
