/*
 * Install the Cert Manager Controller.
 */
module "eks_cert_manager_controller" {
  count = var.enable_cert_manager_controller ? 1: 0
  source = "github.com/Wycliffe-USA/terraform-modules?ref=1.5.0/aws/eks_cert_manager_controller"

  chart_version            = var.cert_manager_controller_helm_chart_version
  certificate_issuer_email = var.certificate_issuer_email
}
