resource "aws_vpc" "_" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

data "aws_availability_zones" "_" {
  state = "available"
}

resource "random_shuffle" "az" {
  input = data.aws_availability_zones._.names
  result_count = var.availability_zone_count
}

resource "aws_subnet" "public" {
  count = var.availability_zone_count
  vpc_id = aws_vpc._.id
  cidr_block = cidrsubnet(aws_vpc._.cidr_block, ceil(log(var.availability_zone_count*2, 2)), count.index)
  availability_zone = random_shuffle.az.result[count.index]
}

resource "aws_subnet" "private" {
  count = var.availability_zone_count
  vpc_id = aws_vpc._.id
  cidr_block = cidrsubnet(aws_vpc._.cidr_block, ceil(log(var.availability_zone_count*2, 2)), count.index + var.availability_zone_count)
  availability_zone = random_shuffle.az.result[count.index]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc._.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    cidr_block = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
}

resource "aws_route_table_association" "public" {
  count = var.availability_zone_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "_" {
  count = var.ha_nat == true ? var.availability_zone_count : 1
}

resource "aws_nat_gateway" "_" {
  count = var.ha_nat == true ? var.availability_zone_count : 1
  allocation_id = aws_eip._[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "private" {
  count = var.ha_nat == true ? var.availability_zone_count : 1
  vpc_id = aws_vpc._.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway._[count.index].id
  }
  route {
    cidr_block = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway._.id
  }
}

resource "aws_route_table_association" "private" {
  count = var.availability_zone_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.ha_nat == true ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

resource "aws_service_discovery_private_dns_namespace" "_" {
  name        = "${var.env}.${var.namespace_root_domain}"
  description = "private namespace"
  vpc         = aws_vpc._.id
}

resource "aws_vpc_dhcp_options" "_" {
  domain_name = aws_service_discovery_private_dns_namespace._.name
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "_" {
  vpc_id = aws_vpc._.id
  dhcp_options_id = aws_vpc_dhcp_options._.id
}