# dynamodb-autoscaler

Terraform module to provision DynamoDB autoscaler.

Autoscaler scales up/down the provisioned OPS for a DynamoDB table based on the load.


---

## Usage


**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases]


```hcl
module "dynamodb_autoscaler" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-dynamodb-autoscaler.git?ref=master"
  namespace                    = "eg"
  stage                        = "dev"
  name                         = "cluster"
  dynamodb_table_name          = "eg-dev-cluster-terraform-state-lock"
  dynamodb_indexes             = ["first-index", "second-index"]
  dynamodb_table_arn           = "arn:aws:dynamodb:us-east-1:123456789012:table/eg-dev-cluster-terraform-state-lock"
  autoscale_write_target       = 50
  autoscale_read_target        = 50
  autoscale_min_read_capacity  = 5
  autoscale_max_read_capacity  = 20
  autoscale_min_write_capacity = 5
  autoscale_max_write_capacity = 20
}
```




## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| autoscale_max_read_capacity | DynamoDB autoscaling max read capacity | number | `20` | no |
| autoscale_max_write_capacity | DynamoDB autoscaling max write capacity | number | `20` | no |
| autoscale_min_read_capacity | DynamoDB autoscaling min read capacity | number | `5` | no |
| autoscale_min_write_capacity | DynamoDB autoscaling min write capacity | number | `5` | no |
| autoscale_read_target | The target value for DynamoDB read autoscaling | number | `50` | no |
| autoscale_write_target | The target value for DynamoDB write autoscaling | number | `50` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| dynamodb_indexes | List of DynamoDB indexes | list(string) | `<list>` | no |
| dynamodb_table_arn | DynamoDB table ARN | string | - | yes |
| dynamodb_table_name | DynamoDB table name | string | - | yes |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| name | Name  (e.g. `app` or `cluster`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | `` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`, `infra`) | string | `` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map(string) | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| appautoscaling_read_target_id | Appautoscaling read target ID |
| appautoscaling_read_target_index_id | Appautoscaling read target index ID |
| appautoscaling_write_target_id | Appautoscaling write target ID |
| appautoscaling_write_target_index_id | Appautoscaling write target index ID |
| autoscaler_iam_role_arn | Autoscaler IAM Role ARN |
| autoscaler_iam_role_id | Autoscaler IAM Role ID |



### Code from:
- https://github.com/cloudposse/terraform-aws-dynamodb-autoscaler
- https://www.terraform.io/docs/modules/index.html