################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block          = var.use_ipam_pool ? null : var.cidr
  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_netmask_length

  assign_generated_ipv6_cidr_block = var.enable_ipv6 && !var.use_ipam_pool ? true : null
  ipv6_cidr_block                  = var.ipv6_cidr
  ipv6_ipam_pool_id                = var.ipv6_ipam_pool_id
  ipv6_netmask_length              = var.ipv6_netmask_length

  instance_tenancy               = var.instance_tenancy
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_dns_support             = var.enable_dns_support
  enable_classiclink             = null # https://github.com/hashicorp/terraform/issues/31730
  enable_classiclink_dns_support = null # https://github.com/hashicorp/terraform/issues/31730

  tags = merge(
    local.tags,
    var.vpc_tags,
    { "Name" = local.name },
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = var.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  # Do not turn this into `local.vpc_id`
  vpc_id = aws_vpc.this[0].id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

resource "aws_default_security_group" "this" {
  count = var.create_vpc && var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress
    content {
      self             = lookup(egress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
    }
  }

  tags = merge(
    local.tags,
    var.default_security_group_tags,
    { "Name" = coalesce(var.default_security_group_name, local.name) },
  )
}

################################################################################
# DHCP Options Set
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    { "Name" = local.name },
    local.tags,
    var.dhcp_options_tags,
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = local.name },
    local.tags,
    var.igw_tags,
  )
}

resource "aws_egress_only_internet_gateway" "this" {
  count = var.create_vpc && var.create_egress_only_igw && var.enable_ipv6 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = local.name },
    local.tags,
    var.igw_tags,
  )
}

################################################################################
# Default route
################################################################################

resource "aws_default_route_table" "default" {
  count = var.create_vpc && var.manage_default_route_table ? 1 : 0

  default_route_table_id = aws_vpc.this[0].default_route_table_id
  propagating_vgws       = var.default_route_table_propagating_vgws

  dynamic "route" {
    for_each = var.default_route_table_routes
    content {
      # One of the following destinations must be provided
      cidr_block      = route.value.cidr_block
      ipv6_cidr_block = lookup(route.value, "ipv6_cidr_block", null)

      # One of the following targets must be provided
      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
      gateway_id                = lookup(route.value, "gateway_id", null)
      instance_id               = lookup(route.value, "instance_id", null)
      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
      network_interface_id      = lookup(route.value, "network_interface_id", null)
      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }

  tags = merge(
    local.tags,
    var.default_route_table_tags,
    { "Name" = "${local.name}-default" },
  )
}

################################################################################
# Publiс routes
# One public route table for all public subnets.
################################################################################

resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.public_route_table_tags,
    { "Name" = "${local.name}-${var.public_subnet_suffix}" },
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count = var.create_vpc && var.create_igw && var.enable_ipv6 && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

################################################################################
# Private routes
# There are as many private route tables as the number of private subnets
################################################################################
resource "aws_route_table" "private" {
  for_each = var.create_vpc && length(var.private_subnets) > 0 ? var.private_subnets : {}

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.private_route_table_tags,
    { Name = lookup(each.value, "name", null) != null ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.private_subnet_suffix}" }
  )
}

resource "aws_route" "private_nat_gateway" {
  for_each = var.create_vpc && var.enable_nat_gateway && !(var.enable_transit_gateway) && length(var.private_subnets) > 0 ? var.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = var.nat_gateway_destination_cidr_block #0.0.0.0/0 by default.
  nat_gateway_id         = !(var.one_nat_gateway_per_az) ? aws_nat_gateway.this[0].id : local.availability_zone_nat_gateways[local.availability_zone_public_subnets[each.value.az][0]][0]

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_transit_gateway" {
  for_each = var.create_vpc && var.enable_transit_gateway && !(var.enable_nat_gateway) && length(var.private_subnets) > 0 ? var.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = var.transit_gateway_destination_cidr_block #0.0.0.0/0 by default.
  transit_gateway_id     = var.transit_gateway_id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_custom_routes" {
  for_each = var.create_vpc && length(local.private_subnets_routes) > 0 ? local.private_subnets_routes : {}

  route_table_id         = aws_route_table.private[each.value.source_cidr_block].id
  destination_cidr_block = each.value.destination_cidr_block
  # One of the following targets must be provided
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  gateway_id                = lookup(each.value, "gateway_id", null)
  instance_id               = lookup(each.value, "instance_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_endpoint_id           = lookup(each.value, "vpc_endpoint_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_ipv6_egress" {
  for_each = var.create_vpc && var.create_egress_only_igw && var.enable_ipv6 ? var.private_subnets : {}

  route_table_id              = aws_route_table.private[each.key].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = element(aws_egress_only_internet_gateway.this[*].id, 0)
}

################################################################################
# Database routes
################################################################################
resource "aws_route_table" "database" {
  for_each = var.create_vpc && length(var.database_subnets) > 0 ? var.database_subnets : {}

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.database_route_table_tags,
    { "Name" = "${local.name}-${each.value.az}-${var.database_subnet_suffix}" },
  )
}

resource "aws_route" "database_internet_gateway" {
  count    = var.create_vpc && var.create_igw && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && var.create_database_internet_gateway_route && !(var.create_database_nat_gateway_route) ? 1 : 0

  route_table_id         = aws_route_table.database[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_nat_gateway" {
  for_each = var.create_vpc && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && !(var.create_database_internet_gateway_route) && var.create_database_nat_gateway_route && var.enable_nat_gateway ? var.database_subnets : {}

  route_table_id         = aws_route_table.database[each.key].id
  destination_cidr_block = var.nat_gateway_destination_cidr_block #0.0.0.0/0 by default.
  nat_gateway_id         = !(var.one_nat_gateway_per_az) ? aws_nat_gateway.this[0].id : local.availability_zone_nat_gateways[local.availability_zone_public_subnets[each.value.az][0]][0]

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_ipv6_egress" {
  for_each = var.create_vpc && var.create_egress_only_igw && var.enable_ipv6 && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && var.create_database_internet_gateway_route ?  var.database_subnets : {}

  route_table_id              = aws_route_table.database[each.key].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = element(aws_egress_only_internet_gateway.this[*].id, 0)

  timeouts {
    create = "5m"
  }
}

################################################################################
# Elasticache routes
################################################################################

resource "aws_route_table" "elasticache" {
  for_each = var.create_vpc && length(var.elasticache_subnets) > 0 ? var.elasticache_subnets : {}

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.elasticache_route_table_tags,
    { "Name" = "${local.name}-${each.value.az}-${var.elasticache_subnet_suffix}" },
  )
}

################################################################################
# Intra routes
################################################################################

resource "aws_route_table" "intra" {
  for_each = var.create_vpc && length(var.intra_subnets) > 0 ? var.intra_subnets : {}

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name}-${each.value.az}-${var.intra_subnet_suffix}" },
    local.tags,
    var.intra_route_table_tags,
  )
}

################################################################################
# Kubernetes routes
################################################################################

resource "aws_route_table" "kubernetes" {
  for_each = var.create_vpc && length(var.kubernetes_subnets) > 0 ? var.kubernetes_subnets : {}

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name}-${each.value.az}-${var.kubernetes_subnet_suffix}" },
    local.tags,
    var.kubernetes_route_table_tags,
  )
}

resource "aws_route" "kubernetes_nat_gateway" {
  for_each = var.create_vpc && var.enable_nat_gateway && !(var.enable_transit_gateway) && length(var.kubernetes_subnets) > 0 ? var.kubernetes_subnets : {}

  route_table_id         = aws_route_table.kubernetes[each.key].id
  destination_cidr_block = var.nat_gateway_destination_cidr_block #0.0.0.0/0 by default.
  nat_gateway_id         = !(var.one_nat_gateway_per_az) ? aws_nat_gateway.this[0].id : local.availability_zone_nat_gateways[local.availability_zone_public_subnets[each.value.az][0]][0]

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "kubernetes_transit_gateway" {
  for_each = var.create_vpc && var.enable_transit_gateway && !(var.enable_nat_gateway) && length(var.kubernetes_subnets) > 0 ? var.kubernetes_subnets : {}

  route_table_id         = aws_route_table.kubernetes[each.key].id
  destination_cidr_block = var.transit_gateway_destination_cidr_block #0.0.0.0/0 by default.
  transit_gateway_id     = var.transit_gateway_id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Public subnet
################################################################################

resource "aws_subnet" "public" {
  for_each = var.create_vpc && length(var.public_subnets) > 0 ? var.public_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az

  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.public_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.public_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[index(var.public_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.public_subnet_tags,
    lookup(var.public_subnet_tags_per_az, each.value.az, {}),
    {
      Name             = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.public_subnet_suffix}"
      security_posture = "public"
    }
  )
}

################################################################################
# Private subnet
################################################################################
resource "aws_subnet" "private" {
  for_each = var.create_vpc && length(var.private_subnets) > 0 ? var.private_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az

  assign_ipv6_address_on_creation = var.private_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.private_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[index(var.private_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.private_subnet_tags,
    lookup(var.private_subnet_tags_per_az, each.value.az, {}),
    {
      Name = lookup(each.value, "name", null) != null ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.private_subnet_suffix}"
      security_posture = "private"
    },
  )
}

################################################################################
# Redshift routes
################################################################################
resource "aws_route_table" "redshift" {
  for_each = var.create_vpc && !(var.enable_public_redshift) && length(var.redshift_subnets) > 0 ? var.redshift_subnets : {}
  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.redshift_route_table_tags,
    { "Name" = "${local.name}-${each.value.az}-${var.redshift_subnet_suffix}" },
  )
}

resource "aws_route_table" "redshift_public" {
  for_each = var.create_vpc && var.enable_public_redshift && length(var.redshift_subnets) > 0 ? var.redshift_subnets : {}
  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.redshift_route_table_tags,
    { "Name" = "${local.name}-${each.value.az}-${var.redshift_subnet_suffix}" },
  )
}

################################################################################
# Database subnet
################################################################################

resource "aws_subnet" "database" {
  for_each = var.create_vpc && length(var.database_subnets) > 0 ? var.database_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az
  assign_ipv6_address_on_creation = var.database_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.database_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.database_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.database_subnet_ipv6_prefixes[index(var.database_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.database_subnet_tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.database_subnet_suffix}"
      security_posture = "private"
    },
  )
}

resource "aws_db_subnet_group" "database" {
  count = var.create_vpc && length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0

  name        = lower(coalesce(var.database_subnet_group_name, local.name))
  description = "Database subnet group for ${local.name}"
  subnet_ids  = [ for subnet in aws_subnet.database : subnet.id ]

  tags = merge(
    local.tags,
    var.database_subnet_group_tags,
    {
      "Name" = lower(coalesce(var.database_subnet_group_name, local.name))
    },
  )
}

################################################################################
# Kubernetes subnet
################################################################################

resource "aws_subnet" "kubernetes" {
  for_each = var.create_vpc && length(var.kubernetes_subnets) > 0 ? var.kubernetes_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az
  assign_ipv6_address_on_creation = var.kubernetes_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.kubernetes_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.kubernetes_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.kubernetes_subnet_ipv6_prefixes[index(var.kubernetes_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.kubernetes_subnet_tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.kubernetes_subnet_suffix}"
      security_posture = "private"
    },
  )
}

################################################################################
# Redshift subnet
################################################################################

resource "aws_subnet" "redshift" {
  for_each = var.create_vpc && length(var.redshift_subnets) > 0 ? var.redshift_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az
  assign_ipv6_address_on_creation = var.redshift_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.redshift_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.redshift_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.redshift_subnet_ipv6_prefixes[index(var.private_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.redshift_subnet_tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.redshift_subnet_suffix}"
      security_posture = "private"
    },
  )
}

resource "aws_redshift_subnet_group" "redshift" {
  count = var.create_vpc && length(var.redshift_subnets) > 0 && var.create_redshift_subnet_group ? 1 : 0

  name        = lower(coalesce(var.redshift_subnet_group_name, local.name))
  description = "Redshift subnet group for ${local.name}"
  subnet_ids  = aws_subnet.redshift[*].id

  tags = merge(
    local.tags,
    var.redshift_subnet_group_tags,
    { "Name" = coalesce(var.redshift_subnet_group_name, local.name) },
  )
}

################################################################################
# ElastiCache subnet
################################################################################

resource "aws_subnet" "elasticache" {
  for_each = var.create_vpc && length(var.elasticache_subnets) > 0 ? var.elasticache_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az
  assign_ipv6_address_on_creation = var.elasticache_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.elasticache_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.elasticache_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.elasticache_subnet_ipv6_prefixes[index(var.private_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.elasticache_subnet_tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.elasticache_subnet_suffix}"
      security_posture = "private"
    },
  )
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count = var.create_vpc && length(var.elasticache_subnets) > 0 && var.create_elasticache_subnet_group ? 1 : 0

  name        = coalesce(var.elasticache_subnet_group_name, local.name)
  description = "ElastiCache subnet group for ${local.name}"
  subnet_ids  = [ for subnet in aws_subnet.elasticache : subnet.id ]

  tags = merge(
    local.tags,
    var.elasticache_subnet_group_tags,
    { "Name" = coalesce(var.elasticache_subnet_group_name, local.name) },
  )
}

################################################################################
# Intra subnets - private subnet without NAT gateway
################################################################################
resource "aws_subnet" "intra" {
  for_each = var.create_vpc && length(var.intra_subnets) > 0 ? var.intra_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az
  assign_ipv6_address_on_creation = var.intra_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.intra_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.intra_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.intra_subnet_ipv6_prefixes[index(var.intra_subnets, each.key)]) : null

  tags = merge(
    local.tags,
    var.intra_subnet_tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-${var.intra_subnet_suffix}"
      security_posture = "private"
    },
  )
}

################################################################################
# Transit Gateway subnet
################################################################################
resource "aws_subnet" "transit_gateway_attachment" {
  for_each = var.create_vpc && length(var.transit_gateway_attachment_subnets) > 0 ? var.transit_gateway_attachment_subnets : {}

  vpc_id                          = local.vpc_id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.az

  tags = merge(
    local.tags,
    {
      Name = lookup(each.value, "name", "") != "" ? "${each.value.name}" : "${local.name}-${each.value.az}-tgw-attach"
      security_posture = "private"
    },
  )
}


################################################################################
# Default Network ACLs
################################################################################

resource "aws_default_network_acl" "this" {
  count = var.create_vpc && var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.this[0].default_network_acl_id

  # subnet_ids is using lifecycle ignore_changes, so it is not necessary to list
  # any explicitly. See https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/736.
  subnet_ids = null

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }

  tags = merge(
    { "Name" = coalesce(var.default_network_acl_name, local.name) },
    local.tags,
    var.default_network_acl_tags,
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = [ for subnet in aws_subnet.public : subnet.id ]

  tags = merge(
    { "Name" = "${local.name}-${var.public_subnet_suffix}" },
    local.tags,
    var.public_acl_tags,
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress          = false
  rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress          = true
  rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Private Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = [ for subnet in aws_subnet.private : subnet.id ]

  tags = merge(
    { "Name" = "${local.name}-${var.private_subnet_suffix}" },
    local.tags,
    var.private_acl_tags,
  )
}

resource "aws_network_acl_rule" "private_inbound" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress          = false
  rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress          = true
  rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Intra Network ACLs
################################################################################

resource "aws_network_acl" "intra" {
  count = var.create_vpc && var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = [ for subnet in aws_subnet.intra : subnet.id ]

  tags = merge(
    { "Name" = "${var.intra_subnet_suffix}-${local.name}" },
    local.tags,
    var.intra_acl_tags,
  )
}

resource "aws_network_acl_rule" "intra_inbound" {
  count = var.create_vpc && var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? length(var.intra_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra[0].id

  egress          = false
  rule_number     = var.intra_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.intra_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.intra_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.intra_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.intra_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.intra_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.intra_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.intra_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.intra_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "intra_outbound" {
  count = var.create_vpc && var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? length(var.intra_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra[0].id

  egress          = true
  rule_number     = var.intra_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.intra_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.intra_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.intra_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.intra_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.intra_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.intra_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.intra_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.intra_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Database Network ACLs
################################################################################

resource "aws_network_acl" "database" {
  count = var.create_vpc && var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.tags,
    var.database_acl_tags,
    { "Name" = "${local.name}-${var.database_subnet_suffix}" },
  )
}

resource "aws_network_acl_rule" "database_inbound" {
  count = var.create_vpc && var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? length(var.database_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database[0].id

  egress          = false
  rule_number     = var.database_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.database_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.database_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.database_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.database_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.database_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.database_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.database_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.database_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "database_outbound" {
  count = var.create_vpc && var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? length(var.database_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database[0].id

  egress          = true
  rule_number     = var.database_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.database_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.database_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.database_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.database_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.database_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.database_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.database_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.database_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Kubernetes Network ACLs
################################################################################

resource "aws_network_acl" "kubernetes" {
  count = var.create_vpc && var.kubernetes_dedicated_network_acl && length(var.kubernetes_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.kubernetes[*].id

  tags = merge(
    local.tags,
    var.kubernetes_acl_tags,
    { "Name" = "${local.name}-${var.kubernetes_subnet_suffix}" },
  )
}

resource "aws_network_acl_rule" "kubernetes_inbound" {
  count = var.create_vpc && var.kubernetes_dedicated_network_acl && length(var.kubernetes_subnets) > 0 ? length(var.kubernetes_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.kubernetes[0].id

  egress          = false
  rule_number     = var.kubernetes_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.kubernetes_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.kubernetes_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.kubernetes_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.kubernetes_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.kubernetes_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.kubernetes_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.kubernetes_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.kubernetes_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "kubernetes_outbound" {
  count = var.create_vpc && var.kubernetes_dedicated_network_acl && length(var.kubernetes_subnets) > 0 ? length(var.kubernetes_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database[0].id

  egress          = true
  rule_number     = var.kubernetes_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.kubernetes_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.kubernetes_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.kubernetes_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.kubernetes_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.kubernetes_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.kubernetes_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.kubernetes_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.kubernetes_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Redshift Network ACLs
################################################################################

resource "aws_network_acl" "redshift" {
  count = var.create_vpc && var.redshift_dedicated_network_acl && length(var.redshift_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.redshift[*].id

  tags = merge(
    local.tags,
    var.redshift_acl_tags,
    { "Name" = "${local.name}-${var.redshift_subnet_suffix}" },
  )
}

resource "aws_network_acl_rule" "redshift_inbound" {
  count = var.create_vpc && var.redshift_dedicated_network_acl && length(var.redshift_subnets) > 0 ? length(var.redshift_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.redshift[0].id

  egress          = false
  rule_number     = var.redshift_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.redshift_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.redshift_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.redshift_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.redshift_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.redshift_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.redshift_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.redshift_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.redshift_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "redshift_outbound" {
  count = var.create_vpc && var.redshift_dedicated_network_acl && length(var.redshift_subnets) > 0 ? length(var.redshift_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.redshift[0].id

  egress          = true
  rule_number     = var.redshift_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.redshift_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.redshift_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.redshift_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.redshift_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.redshift_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.redshift_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.redshift_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.redshift_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Elasticache Network ACLs
################################################################################

resource "aws_network_acl" "elasticache" {
  count = var.create_vpc && var.elasticache_dedicated_network_acl && length(var.elasticache_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.elasticache[*].id

  tags = merge(
    local.tags,
    var.elasticache_acl_tags,
    { "Name" = "${local.name}-${var.elasticache_subnet_suffix}" },
  )
}

resource "aws_network_acl_rule" "elasticache_inbound" {
  count = var.create_vpc && var.elasticache_dedicated_network_acl && length(var.elasticache_subnets) > 0 ? length(var.elasticache_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.elasticache[0].id

  egress          = false
  rule_number     = var.elasticache_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.elasticache_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.elasticache_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.elasticache_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.elasticache_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.elasticache_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.elasticache_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.elasticache_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.elasticache_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "elasticache_outbound" {
  count = var.create_vpc && var.elasticache_dedicated_network_acl && length(var.elasticache_subnets) > 0 ? length(var.elasticache_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.elasticache[0].id

  egress          = true
  rule_number     = var.elasticache_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.elasticache_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.elasticache_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.elasticache_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.elasticache_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.elasticache_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.elasticache_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.elasticache_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.elasticache_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# NAT Gateway
################################################################################
resource "aws_eip" "nat" {
  count = var.create_vpc && var.enable_nat_gateway && !(var.reuse_nat_ips) ? local.nat_gateway_count : 0

  vpc = true

  tags = merge(
    local.tags,
    var.nat_eip_tags,
    {
      "Name" = format(
        "${local.name}-%s",
        element(var.azs, !(var.one_nat_gateway_per_az) ? 0 : count.index),
      )
    },
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_vpc ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.one_nat_gateway_per_az ? count.index : 0,
  )

  subnet_id = local.availability_zone_public_subnets[var.azs[count.index]][0]

  tags = merge(
    {
      "Name" = format(
        "${local.name}-%s",
        element(var.azs, !(var.one_nat_gateway_per_az) ? 0 : count.index),
      )
    },
    local.tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Route table association
################################################################################

resource "aws_route_table_association" "private" {
  for_each = var.create_vpc && length(var.private_subnets) > 0 ? var.private_subnets : {}

  subnet_id = aws_subnet.private[each.key].id
  #Private is the only one with a route table per subnet.
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "database" {
  for_each = var.create_vpc && var.create_database_subnet_route_table && length(var.database_subnets) > 0 ? var.database_subnets : {}

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_route_table_association" "redshift" {
  for_each = var.create_vpc && !(var.enable_public_redshift) && length(var.redshift_subnets) > 0 ? var.redshift_subnets : {}

  subnet_id      = aws_subnet.redshift[each.key].id
  route_table_id = aws_route_table.redshift[0].id
}

resource "aws_route_table_association" "redshift_public" {
  for_each = var.create_vpc  && var.enable_public_redshift && length(var.redshift_subnets) > 0 ? var.redshift_subnets : {}

  subnet_id = aws_subnet.redshift[each.key].id
  route_table_id = aws_route_table.redshift[0].id
}

resource "aws_route_table_association" "elasticache" {
  for_each = var.create_vpc && var.create_elasticache_subnet_route_table && length(var.elasticache_subnets) > 0 ? var.elasticache_subnets : {}

  subnet_id = aws_subnet.elasticache[each.key].id
  route_table_id = aws_route_table.elasticache[0].id
}

resource "aws_route_table_association" "intra" {
  for_each = var.create_vpc && length(var.intra_subnets) > 0 ? var.intra_subnets : {}

  subnet_id      = aws_subnet.intra[each.key].id
  route_table_id = aws_route_table.intra[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = var.create_vpc && length(var.public_subnets) > 0 ? var.public_subnets : {}

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Customer Gateways
################################################################################

resource "aws_customer_gateway" "this" {
  for_each = var.customer_gateways

  bgp_asn     = each.value["bgp_asn"]
  ip_address  = each.value["ip_address"]
  device_name = lookup(each.value, "device_name", null)
  type        = "ipsec.1"

  tags = merge(
    local.tags,
    var.customer_gateway_tags,
    { name = "${local.name}-${each.key}" },
  )
}

################################################################################
# VPN Gateway
################################################################################

resource "aws_vpn_gateway" "this" {
  count = var.create_vpc && var.enable_vpn_gateway ? 1 : 0

  vpc_id            = local.vpc_id
  amazon_side_asn   = var.amazon_side_asn
  availability_zone = var.vpn_gateway_az

  tags = merge(
    local.tags,
    var.vpn_gateway_tags,
    { "Name" = local.name },
  )
}

resource "aws_vpn_gateway_attachment" "this" {
  count = var.vpn_gateway_id != "" ? 1 : 0

  vpc_id         = local.vpc_id
  vpn_gateway_id = var.vpn_gateway_id
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count = var.create_vpc && var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? 1 : 0

  route_table_id = element(aws_route_table.public[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this[*].id,
      aws_vpn_gateway_attachment.this[*].vpn_gateway_id,
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.create_vpc && var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0

  route_table_id = element(aws_route_table.private[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this[*].id,
      aws_vpn_gateway_attachment.this[*].vpn_gateway_id,
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "intra" {
  count = var.create_vpc && var.propagate_intra_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.intra_subnets) : 0

  route_table_id = element(aws_route_table.intra[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this[*].id,
      aws_vpn_gateway_attachment.this[*].vpn_gateway_id,
    ),
    count.index,
  )
}

################################################################################
# Defaults
################################################################################

resource "aws_default_vpc" "this" {
  count = var.manage_default_vpc ? 1 : 0

  enable_dns_support   = var.default_vpc_enable_dns_support
  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames
  enable_classiclink   = null # https://github.com/hashicorp/terraform/issues/31730

  tags = merge(
    local.tags,
    var.default_vpc_tags,
    { "Name" = coalesce(var.default_vpc_name, "default") },
  )
}