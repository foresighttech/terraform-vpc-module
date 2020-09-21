resource "aws_ec2_transit_gateway" "_" {
    auto_accept_shared_attachments = "enable"
}

resource "aws_ram_resource_association" "_" {
  resource_arn       = aws_ec2_transit_gateway._.arn
  resource_share_arn = aws_ram_resource_share._.arn
}

resource "aws_ec2_transit_gateway_vpc_attachment" "_" {
    subnet_ids = aws_subnet.private[*].id
    transit_gateway_id = aws_ec2_transit_gateway._.id
    vpc_id = aws_vpc._.id
}

resource "aws_ec2_transit_gateway_route" "_" {
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment._.id
    transit_gateway_route_table_id = aws_ec2_transit_gateway._.association_default_route_table_id
}