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
  cidr_block = cidrsubnet(aws_vpc._.cidr_block, ceil(log(var.availability_zone_count*2), 2), count.index)
  availability_zone = random_shuffle.az.result[count.index]
}

resource "aws_subnet" "private" {
  count = var.availability_zone_count
  vpc_id = aws_vpc._.id
  cidr_block = cidrsubnet(aws_vpc._.cidr_block, ceil(log(var.availability_zone_count*2), 2), count.index + var.availability_zone_count)
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
}

resource "aws_route_table_association" "private" {
  count = var.availability_zone_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.ha_nat == true ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}