/*
 * Install the Cert Manager Controller.
 */
module "eks_load_balancer_controller" {
  count    = var.enable_load_balancer_controller ? 1: 0

  app_name = var.app_name
  app_env  = var.app_env
  source = "github.com/Wycliffe-USA/terraform-modules//aws/eks_load_balancer_controller?ref=1.9.0"

  chart_version             = var.load_balancer_controller_helm_chart_version
  cluster_name              = module.eks.cluster_name
  aws_iam_oidc_provider_arn = module.eks.oidc_provider_arn

  tags = local.tags
}
