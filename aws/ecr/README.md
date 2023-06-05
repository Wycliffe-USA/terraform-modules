# aws/ecr - EC2 Container Service Image Repository
This module is used to create an ECS image repository for storage of a Docker
image.

## What this does

 - Create ECR repository named `var.repo_name`
 - Attache ECR policy to allow appropriate access

## Required Inputs

 - `repo_name` - Name of repo, ex: Doorman, IdP, etc.
 - `ecsServiceRole_arn` - ARN for ECS Service Role
 - `ecsInstanceRole_arn` - ARN for ECS Instance Role
 - `cd_user_arn` - ARN for an IAM user used by a Continuous Delivery service
    for pushing Docker images

## Optional Inputs

 - `image_retention_count` - The number of images to retain in addition to any images identified by `image_retention_tags`. The images are sorted by the push time and the newest images are retained. If omitted or set to 0, no lifecycle rule will be created.
 - `image_retention_tags` - A list of image tags to retain. The latest image matching each tag in this list will be retained. The matching rule interprets these strings as a tag prefix, so an image tag that begins with a string in this list will match even if the actual tag is longer. No more than 999 tags may be specified in this list.
 - `tags` - Additional tags to add to resources created by this module.

## Outputs

 - `arn` - The repository arn.
 - `repository_url` - The repository url. Ex: `1234567890.dkr.ecr.us-east-1.amazonaws.com/repo-name`

## Usage Example

```hcl
module "ecr" {
  source = "github.com/silinternational/terraform-modules//aws/ecr"
  repo_name = "${var.app_name}-${var.app_env}"
  ecsInstanceRole_arn = "${data.terraform_remote_state.cluster.ecsInstanceRole_arn}"
  ecsServiceRole_arn = "${data.terraform_remote_state.cluster.ecsServiceRole_arn}"
  cd_user_arn = "${data.terraform_remote_state.cluster.cd_user_arn}"
  image_retention_count = 10
  image_retention_tags = ["latest", "main", "develop"]
}
```