/*
 * Install the Cert Manager Controller via terraform-iaac/cert-manager module.
 */
module "cert_manager" {
  source  = "terraform-iaac/cert-manager/kubernetes"
  chart_version = var.chart_version
  cluster_issuer_email = var.certificate_issuer_email
}