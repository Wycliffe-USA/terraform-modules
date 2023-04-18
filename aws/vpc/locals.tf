locals {
  name = length(var.name) > 0 ? "${var.name}" : "${var.app_name}-${var.app_env}"

  #Set the NAT Gateway count. enable_nat_gateway must be true.
  #Then, by default, there will be one NAT GW in the VPC.  If one_nat_gateway_per_az is true, then there will be one per zone.
  nat_gateway_count = var.enable_nat_gateway ? var.one_nat_gateway_per_az ? length(var.azs) : 1 : 0

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc_ipv4_cidr_block_association.this[0].vpc_id, aws_vpc.this[0].id, "")

  tags = merge(
    {
      app_name           = var.app_name
      app_env            = var.app_env
      owner              = "zz-wycliffe-it-systems-engineering-architecture-team-staff-usa@wycliffe.org"
      terraform_managed  = "true"
    },
    var.tags,
  )

  #Get a map of private subnets by the availability zones containing them.
  availability_zone_private_subnets = {
    for s in aws_subnet.private : s.availability_zone => s.id...
  }

  #Get a map of subnets by the availability zones containing them.
  availability_zone_public_subnets = {
    for s in aws_subnet.public : s.availability_zone => s.id...
  }

  #Get a map of NAT gateways by the subnets containing them.
  availability_zone_nat_gateways = {
    for n in aws_nat_gateway.this : n.subnet_id => n.id...
  }

  #Get a map of routes by the private subnets containing them.
  #Formatted as a flattend list due to complexities of gathering the data.
  private_subnets_routes_as_list = flatten([
    for sk, sv in var.private_subnets : [
      for route in sv.routes : {
         source_cidr_block      = sk
         destination_cidr_block = route.destination_cidr_block
         network_interface_id   = lookup(route, "network_interface_id", null)
         transit_gateway_id     = lookup(route, "transit_gateway_id", null)
       }
     ] if length(sv.routes) > 0
  ])
  private_subnets_routes = { #Format as a map
    for r in local.private_subnets_routes_as_list : "${r.source_cidr_block}_to_${r.destination_cidr_block}" => r
  }

  #Get external IPs for NAT Gateways.
  nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : try(aws_eip.nat[*].id, [])
}