output "vpc_id" {
    value = aws_vpc._.id
}

output "public_subnet_ids" {
    value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
    value = aws_subnet.private[*].id
}

output "dns_namespace" {
    value = aws_service_discovery_private_dns_namespace._.name
}

output "tgw_id" {
    value = aws_ec2_transit_gateway._.id
}