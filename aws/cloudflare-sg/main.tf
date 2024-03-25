module "cf_ips" {
  source = "github.com/wycliffe-usa/terraform-modules//cloudflare/ips?ref=1.7.4"
}

resource "aws_security_group" "cloudflare_https" {
  name        = "cloudflare-https"
  description = "Allow HTTPS traffic from Cloudflare"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "cloudflare_ipv4" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cloudflare_https.id
  cidr_blocks       = module.cf_ips.ipv4_cidrs
}
