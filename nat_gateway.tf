
## Elastic ip for the nat_gatway
resource "aws_eip" "mrtonero_eip" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "mrtonero_eip ${count.index + 1}"
  }
}

## Nat gateway 
# NAT Gateway (one per AZ)
resource "aws_nat_gateway" "mrtonero_nat_gateway" {
  for_each = {
    for idx, eip in aws_eip.mrtonero_eip : idx => eip
  }
  allocation_id = each.value.id
  subnet_id     = aws_subnet.public_subnet[each.key % length(aws_subnet.public_subnet)].id

  tags = {
    Name = "mrtonero-Nat_gateway${each.key}"
  }
}

resource "aws_route_table" "private_rt" {
  count = length(aws_subnet.private_subnet)
  vpc_id = aws_vpc.mrtonero-vpc.id

  tags = {
    Name = "private_rt ${count.index}"
  }

}

resource "aws_route" "private_route" {
  count = length(aws_subnet.private_subnet)
  route_table_id = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.mrtonero_nat_gateway[count.index].id

  
}

resource "aws_route_table_association" "private_rt_association" {
count = length(aws_subnet.private_subnet)
  route_table_id = aws_route_table.private_rt[count.index].id
  subnet_id = aws_subnet.private_subnet[count.index].id
}