data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13.1"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  eks_managed_node_group_defaults = {
    name                 = local.name
    launch_template_name = "${local.name}"
    ami_type             = "AL2_x86_64"
    instance_types       = var.default_instance_types

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true

    launch_template_tags = merge(
      local.tags,
      {
        "Name" = "${local.name}-eks"
      },
    )
  }

  eks_managed_node_groups = {
    # Sytesm node group.  Intended primarily for cluster qourum & high availability.
    system_node_group = {
      name                 = "${local.name}-system"
      launch_template_name = "${local.name}-system"
      instance_types       = var.system_instance_types

      min_size     = var.node_group_system_min_size
      max_size     = var.node_group_system_max_size
      desired_size = var.node_group_system_desired_size

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      # This will get added to what AWS provides
      bootstrap_extra_args = <<-EOT
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      taints = [
        {
          key    = "system"
          value  = "systemGroup"
          effect = "NO_SCHEDULE"
        }
      ]

      launch_template_tags = merge(
        local.tags,
        {
          "Name" = "${local.name}-eks-system"
        },
      )
    }

    # Primary workload node group.  Intended for general workloads & applications.
    workload_node_group = {
      name                 = "${local.name}-workload"
      launch_template_name = "${local.name}-workload"
      instance_types       = length(var.workload_instance_types) > 0 ? var.workload_instance_types : var.default_instance_types

      min_size     = var.node_group_workload_min_size != null ? var.node_group_workload_min_size : var.node_group_default_min_size
      max_size     = var.node_group_workload_max_size != null ? var.node_group_workload_max_size : var.node_group_default_max_size
      desired_size = var.node_group_workload_desired_size != null ? var.node_group_workload_desired_size : var.node_group_default_desired_size

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      # This will get added to what AWS provides
      bootstrap_extra_args = <<-EOT
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      launch_template_tags = merge(
        local.tags,
        {
          "Name" = "${local.name}-eks-workload"
        },
      )
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = local.eks_admins_by_user

  tags                 = local.tags
}

#The IRSA module creates an IAM Role for Service Accounts to use in the cluster.
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}