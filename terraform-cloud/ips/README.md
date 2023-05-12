# terraform-cloud/ips - Terraform Cloud IP Addresses
This module is used to pull the current list of IP ranges for app.terraform.io for IPv4

## What this does

 - Provide outputs for `ipv4_cidrs`

## Required Inputs

 ~none~

## Outputs

 - `ipv4_cidrs` - List of IPv4 IP ranges

## Example Usage

```hcl
module "tf_ips" {
  source = "github.com/wycliffe-usa/terraform-modules//terraform-cloud/ips"
}

resource "aws_security_group" "terraform_https" {
  name        = "terraform-https"
  description = "Allow HTTPS traffic from terraform"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "terraform_ipv4" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.terraform_https.id}"
  cidr_blocks       = ["${module.tf_ips.ipv4_cidrs}"]
}
```