#Create a group used to manage the cluster.
#Members added to this group will gain cluster admin rights.
#Note: Terraform must be run be run again once the membership is updated.
resource "aws_iam_group" "eks_admins" {
  name = "${local.name}-eks-administrators"
}

resource "aws_iam_group_policy_attachment" "eks_admins_require_mfa" {
  group      = aws_iam_group.eks_admins.name
  policy_arn = data.aws_iam_policy.require_mfa.arn
}

data "aws_iam_group" "eks_admins" {
  group_name = aws_iam_group.eks_admins.name
}

data "aws_iam_policy" "require_mfa" {
  name = "Require_MFA"
}
