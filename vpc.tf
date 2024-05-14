## VPC creation

resource "aws_vpc" "mrtonero-vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "mrtonero-vpc"
  }
}

## subnet creation

locals {
  public_subnet_cidrs = [
    "192.168.0.0/18",
    "192.168.64.0/18"
  ]
  private_subnet_cidrs = [
    "192.168.128.0/18",
    "192.168.192.0/18"
  ]
  availability_zone = [
    "us-east-2a",
    "us-east-2b"
  ]
}

## Public subnet 
resource "aws_subnet" "public_subnet" {
  count                                          = length(local.public_subnet_cidrs)
  vpc_id                                         = aws_vpc.mrtonero-vpc.id
  cidr_block                                     = local.public_subnet_cidrs[count.index]
  availability_zone                              = local.availability_zone[count.index]
  map_public_ip_on_launch                        = true
  enable_resource_name_dns_a_record_on_launch    = true
  
  tags = {
    Name = "mrtonero_public_subnet ${count.index + 1}"
  }
}

## Private subnet 
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnet_cidrs)
  vpc_id            = aws_vpc.mrtonero-vpc.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zone[count.index]

  tags = {
    Name = "mrtonero_private_subnet ${count.index + 1}"
  }
}

# internet gateway
resource "aws_internet_gateway" "mrtonero_igw" {
  tags = {
    Name = "mrtonero_igw"
  }
}

resource "aws_internet_gateway_attachment" "mrtonero_igw_attachment" {
  vpc_id              = aws_vpc.mrtonero-vpc.id
  internet_gateway_id = aws_internet_gateway.mrtonero_igw.id
}

## Route table for the IGW interface
resource "aws_route_table" "igw_route_table" {
  vpc_id = aws_vpc.mrtonero-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mrtonero_igw.id
  }
  tags = {
    Name = "igw_route_table"
  }
}

## Elastic ip for the nat_gatway
resource "aws_eip" "mrtonero_eip" {
  count  = 2
  domain = "vpc"
}



## Nat gateway 
resource "aws_nat_gateway" "mrtonero_nat_gateway" {
  for_each = {
    for idx, eip in aws_eip.mrtonero_eip : idx => eip
  }
  allocation_id = each.value.id
  subnet_id     = aws_subnet.public_subnet[each.key % length(aws_subnet.public_subnet)].id
}