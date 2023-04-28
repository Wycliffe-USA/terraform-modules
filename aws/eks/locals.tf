locals {
  name            = "${var.app_name}-${var.app_env}"
  cluster_name    = length(var.cluster_name) > 0 ? var.cluster_name : "${var.app_name}-${var.app_env}"
  cluster_version = var.cluster_version
  region          = "us-east-1"

  vpc_cidr = data.aws_vpc.this.cidr_block
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge(
    {
      app_name           = var.app_name
      app_env            = var.app_env
      owner              = "zz-wycliffe-it-systems-engineering-architecture-team-staff-usa@wycliffe.org"
      terraform_managed  = "true"
    },
    var.tags,
  )

  #Create a list of user objects from the eks-admins group created under iam_group.tf.
  eks_admins_by_user = [
    for u in data.aws_iam_group.eks_admins.users : {
      userarn  = u.arn
      username = u.user_name
      groups   = ["system:masters"]
    }
  ]
}

data "aws_vpc" "this" {
  id = var.vpc_id
}
