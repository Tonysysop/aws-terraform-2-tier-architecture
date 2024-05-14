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
    Name = "Mrtonero_Public_subnet ${count.index + 1}"
  }
}

## Private subnet 
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnet_cidrs)
  vpc_id            = aws_vpc.mrtonero-vpc.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zone[count.index]

  tags = {
    Name = "Mrtonero_Private_subnet ${count.index + 1}"
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

# Route table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mrtonero-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mrtonero_igw.id
  }
  tags = {
    Name = "Public_rt"
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "Public_rt_association" {
  count           = length(aws_subnet.public_subnet[*])
  route_table_id  = aws_route_table.public_rt.id
  subnet_id       = aws_subnet.public_subnet[count.index].id
}
