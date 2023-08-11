/*
 * Create ECR repository
 */
resource "aws_ecr_repository" "repo" {
  name = var.repo_name
  tags = local.tags
}

locals {
  tags = merge(
    {
      owner              = "zz-wycliffe-it-systems-engineering-architecture-team-staff-usa@wycliffe.org"
      terraform_managed  = "true"
    },
    var.tags,
  )
}

resource "aws_ecr_repository_policy" "ecs_policy" {
  count      = var.ecs_instance_role_arn != "" ? 1 : 0
  repository = aws_ecr_repository.repo.name
  policy     = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "ECS Pull Access"
        Effect = "Allow"
        Principal = {
          AWS = [
            var.ecs_instance_role_arn,
            var.ecs_service_role_arn,
          ]
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ]
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "eks_policy" {
  count      = var.eks_cluster_role_arn != "" ? 1 : 0
  repository = aws_ecr_repository.repo.name
  policy     = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "ECS Pull Access"
        Effect = "Allow"
        Principal = {
          AWS = [
            var.eks_cluster_role_arn,
          ]
        },
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "policy" {
  count = var.image_retention_count > 0 ? 1 : 0

  repository = aws_ecr_repository.repo.name
  /*
    This lifecycle policy expires images older than the `var.image_retention_count` newest images and not matched by
    any of the tags given in `var.image_retention_tags`. Each tag in `var.image_retention_tags` must be added as a
    separate rule because the list of tags within a rule must all be present on an image for it to match the rule.
  */
  policy     = jsonencode({
    rules = concat(
      [
        for i, tag in var.image_retention_tags : {
          rulePriority = i + 1
          description  = "Keep specified images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = [tag]
            countType     = "imageCountMoreThan"
            countNumber   = 1
          },
          action = {
            type = "expire"
          }
        }
      ],
      [
        {
          rulePriority = 1000,
          description  = "Keep only image_retention_count images"
          selection = {
            tagStatus   = "any"
            countType   = "imageCountMoreThan"
            countNumber = var.image_retention_count
          },
          action = {
            type = "expire"
          }
        }
      ]
    )
  })
}