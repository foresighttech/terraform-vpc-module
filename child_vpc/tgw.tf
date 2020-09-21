resource "aws_ec2_transit_gateway_vpc_attachment" "_" {
    subnet_ids = aws_subnet.private[*].id
    transit_gateway_id = var.tgw_id
    vpc_id = aws_vpc._.id
}