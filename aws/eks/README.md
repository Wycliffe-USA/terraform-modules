# AWS EKS Terraform module

This is an opinionated Terraform module which creates EKS resources on AWS. It can be used to create a generic Kubernetes cluster for a variety of workloads.
This module uses terraform-aws-modules/terraform-aws-eks in the background.

## Usage for typical EKS Cluster

```hcl
module "eks" {
  source = "github.com/Wycliffe-USA/terraform-modules/aws/eks"

  app_name        = var.app_name
  app_env         = var.app_env
  cluster_version = "1.25"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.kubernetes_subnets
  
  workload_instance_types = ["t3.medium"]

  #Supporting resources
  module "vpc" {
    source = "github.com/Wycliffe-USA/terraform-modules/aws/vpc"

    cidr = var.vpc_cidr
    app_name = local.app_name
    app_env  = local.app_env

    azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

    public_subnets                     = var.public_subnets
    private_subnets                    = var.private_subnets
    kubernetes_subnets                 = var.kubernetes_subnets

    create_igw         = true
    enable_nat_gateway = true

    create_egress_only_igw          = false

    manage_default_route_table = true

    tags = local.tags
  }
}
```
## Node Groups

By default, the module creates two node groups; system and workload. The system node group, has a desired count of 1 micro node by default, and is 'tainted' to keep non-system workloads off the node.
The system node(s) are solely there for high availability.
The workload node group has a desired count of 2 small nodes by default. This workload group is intended to run your workloads. If you plan to have a desired node count of 3 or more, you can reduce the system node count to 0.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.58 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.58 |
| <a name="kubernetes"></a> [aws](#provider\_kubernetes) | >= 2.20.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of the application or purpose of this VPC.  Used for naming resources in combination with app_env. | `string` | `""` | no |
| <a name="input_app_env"></a> [app\_env](#input\_app\_env) | Tier of the application or purpose of this VPC.  Used for naming resources in combination with app_name. Example: Prod, Test, Dev | `string` | `"Prod"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | `""` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`) | `string` | `""` | yes |
| <a name="input_default_instance_types"></a> [default\_instance\_types](#input\_default\_instance\_types) | Default instance types. | `list(string)` | `["t3.small"]` | no |
| <a name="input_system_instance_types"></a> [system\_instance\_types](#input\_system\_instance\_types) | System instance types. | `list(string)` | `["t3.micro"]` | no |
| <a name="input_workload_instance_types"></a> [workload\_instance\_types](#input\_workload\_instance\_types) | Workload instance types. Uses default if not defined. | `list(string)` | `[]` | no |
| <a name="input_control_plane_subnet_ids"></a> [control_plane_subnet_ids](#input\_control\_plane\_subnet\_ids) | A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane. | `list(string)` | `[]` | no |
| <a name="input_node_group_default_max_size"></a> [node\_group\_default\_max\_size](#input\_control\_plane\_subnet\_ids) | Maximum size of the default node group. | `number` | `3` | no |
| <a name="input_node_group_default_min_size"></a> [node\_group\_default\_min\_size](#input\_node\_group\_default\_min\_size) | Minimum size of the default node group. | `number` | `1` | no |
| <a name="input_node_group_default_desired_size"></a> [node\_group\_default\_desired\_size](#input\_node\_group\_default\_desired\_size) | Desired size of the default node group. | `number` | `2` | no |
| <a name="input_node_group_system_max_size"></a> [node\_group\_system\_max\_size](#input\_node\_group\_system\_max\_size) | Maximum size of the system node group. | `number` | `2` | no |
| <a name="input_node_group_system_min_size"></a> [node\_group\_system\_min\_size](#input\_node\_group\_system\_min\_size) | Minimum size of the system node group. | `number` | `1` | no |
| <a name="input_node_group_system_desired_size"></a> [node\_group\_system\_desired\_size](#input\_node\_group\_system\_desired\_size) | Desired size of the system node group. | `number` | `1` | no |
| <a name="input_node_group_workload_max_size"></a> [node\_group\_workload\_max\_size](#input\_node\_group\_workload\_max\_size) | Maximum size of the workload node group. | `number` | `null` | no |
| <a name="input_node_group_workload_min_size"></a> [node\_group\_workload\_min\_size](#input\_node\_group\_workload\_min\_size) | Minimum size of the workload node group. | `number` | `null` | no |
| <a name="input_node_group_workload_desired_size"></a> [node\_group\_workload\_desired\_size](#input\_node\_group\_workload\_desired\_size) | Desired size of the workload node group. | `number` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs to place Kubernetes nodes into. | `list(string)` | `` | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of additional tags to pass to this module. | `map(any)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc_id](#input\_vpc_id) | The ID of the VPC for the cluster. | `string` | `` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster_certificate_authority_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts |
| <a name="cluster_name"></a> [cluster_name](#output\_cluster\_name) | The name of the EKS cluster |
| <a name="cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The Kubernetes version for the cluster |
| <a name="cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version for the cluster |
| <a name="cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED` |
| <a name="cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="cluster_iam_admins_group_name"></a> [cluster\_iam\_admins\_group\_name](#output\_cluster\_iam\_admins\_group\_name) | IAM group for admins. Add users to this group for administrative priviledges. |
| <a name="kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The Amazon Resource Name (ARN) of the key |
| <a name="kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The globally unique identifier for the key |
| <a name="kms_key_policy"></a> [kms\_key\_policy](#output\_kms\_key\_policy) | The IAM resource policy set on the key |
| <a name="cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | ID of the cluster security group |
| <a name="node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="cluster_tls_certificate_sha1_fingerprint"></a> [cluster\_tls\_certificate\_sha1\_fingerprint](#output\_cluster\_tls\_certificate\_sha1\_fingerprint) | The SHA1 fingerprint of the public key of the cluster's certificate |
| <a name="cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="cluster_iam_role_unique_id"></a> [cluster\_iam\_role\_unique\_id](#output\_cluster\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="cluster_addons"></a> [cluster\_addons](#output\_cluster\_addons) | Map of attribute maps for all EKS cluster addons enabled |
| <a name="cluster_identity_providers"></a> [cluster_identity_providers](#output\_cluster_identity_providers) | Map of attribute maps for all EKS identity providers enabled |
| <a name="cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of cloudwatch log group created |
| <a name="cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | Arn of cloudwatch log group created |
| <a name="eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | Map of attribute maps for all EKS managed node groups created |
| <a name="eks_managed_node_groups_autoscaling_group_names"></a> [eks\_managed\_node\_groups\_autoscaling\_group\_names](#output\_eks\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by EKS managed node groups |
| <a name="self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | Map of attribute maps for all self managed node groups created |
| <a name="self_managed_node_groups_autoscaling_group_names"></a> [self\_managed\_node\_groups\_autoscaling\_group\_names](#output\_self\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by self-managed node groups |
| <a name="asdf"></a> [asdf](#output\_asdf) | asdfDescription |
| <a name="asdf"></a> [asdf](#output\_asdf) | asdfDescription |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Anton Babenko](https://github.com/antonbabenko) with help from [these awesome contributors](https://github.com/terraform-aws-modules/terraform-aws-vpc/graphs/contributors).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/LICENSE) for full details.