# cloudflare/ips - Cloudflare IP Addresses
This module is used to pull the current list of IP ranges for Cloudflare for IPv4 and IPv6

## What this does

 - Provide outputs for `ipv4_cidrs` and `ipv6_cidrs`

## Required Inputs

 ~none~

## Required Providers
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.x.x"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

## Outputs

 - `ipv4_cidrs` - List of IPv4 IP ranges
 - `ipv6_cidrs` - List of IPv6 IP ranges

## Example Usage

```hcl
module "cf_ips" {
  source = "github.com/silinternational/terraform-modules//cloudflare/ips"
}

resource "aws_security_group" "cloudflare_https" {
  name        = "cloudflare-https"
  description = "Allow HTTPS traffic from Cloudflare"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "cloudflare_ipv4" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.cloudflare_https.id}"
  cidr_blocks       = ["${module.cf_ips.ipv4_cidrs}"]
}
```