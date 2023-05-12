locals {
  # Extract OIDC Provider from OIDC Provider ARN
  aws_iam_oidc_provider_extract_from_arn = element(split("oidc-provider/", "${var.aws_iam_oidc_provider_arn}"), 1)
}

# To find Helm versions
# helm repo add eks https://aws.github.io/eks-charts
# helm repo update
# helm search repo
################################################################################

/*
 * Install the AWS Load Balancer Controller via Helm.
 */
resource "helm_release" "loadbalancer_controller" {
  depends_on = [aws_iam_role.lbc_iam_role]
  name       = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  namespace = "kube-system"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller" # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc_iam_role.arn
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  #Only needed for limited access clusters where different cluster admins have a variety of trust levels.
  # set {
  #   name  = "vpcId"
  #   value = var.vpc_id
  # }

  # set {
  #   name  = "region"
  #   value = var.aws_region
  # }
}

/*
 *Create a Kubernetes Ingress Class for AWS Load Balancer Controller.
 *By creating an Ingress class and marking it as the default, we are telling Kubernetes to use the AWS Load Balancer Controller to handle all incoming traffic to our application.
 */
# Resource: Kubernetes Ingress Class
resource "kubernetes_ingress_class_v1" "ingress_class_default" {
  depends_on = [helm_release.loadbalancer_controller]
  metadata {
    name = "aws-ingress-class"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }
  spec {
    controller = "ingress.k8s.aws/alb"
  }
}

/*
 *Create IAM role and policy that will allow the controller to manage AWS resources such as ALBs.
 */
# Resource: Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "${local.name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.response_body

  tags        = var.tags
}

# Resource: Create IAM Role 
resource "aws_iam_role" "lbc_iam_role" {
  name = "${local.name}-lbc-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${var.aws_iam_oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_provider_extract_from_arn}:aud" : "sts.amazonaws.com",
            "${local.aws_iam_oidc_provider_extract_from_arn}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })

  tags = merge(
      var.tags,
      {
         tag-key = "AWSLoadBalancerControllerIAMPolicy"
      },
    )
}

# Associate Load Balanacer Controller IAM Policy to  IAM Role
resource "aws_iam_role_policy_attachment" "lbc_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.lbc_iam_policy.arn
  role       = aws_iam_role.lbc_iam_role.name
}

# Datasource: AWS Load Balancer Controller IAM Policy get from aws-load-balancer-controller/ GIT Repo (latest)
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

