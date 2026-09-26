
resource "aws_vpc" "vpcitmentorsoft" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

resource "aws_internet_gateway" "igwitmentorsoft" {
  vpc_id = aws_vpc.vpcitmentorsoft.id
  tags   = var.tags
  depends_on = [
    aws_vpc.vpcitmentorsoft
 ]
}

resource "aws_subnet" "sbnpublic" {
  count = 1

  vpc_id                  = aws_vpc.vpcitmentorsoft.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = var.tags
  depends_on = [
    aws_vpc.vpcitmentorsoft
  ]
}

resource "aws_subnet" "sbnapp" {
  count = 1

  vpc_id            = aws_vpc.vpcitmentorsoft.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = var.tags
  depends_on = [
    aws_vpc.vpcitmentorsoft
  ]
}

resource "aws_subnet" "sbndb" {
  count = 1

  vpc_id            = aws_vpc.vpcitmentorsoft.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = var.tags
  depends_on = [
    aws_vpc.vpcitmentorsoft
  ]
}

resource "aws_eip" "eipitmentorsoft" {
  count  = 1
  domain = "vpc"

  tags = var.tags
}

resource "aws_nat_gateway" "natitmentorsoft" {
  count = 1

  allocation_id = aws_eip.eipitmentorsoft[count.index].id
  subnet_id     = aws_subnet.sbnpublic[count.index].id

  tags = var.tags
  depends_on = [aws_internet_gateway.igwitmentorsoft]
}

resource "aws_route_table" "rttpublic_itmentorsoft" {
  vpc_id = aws_vpc.vpcitmentorsoft.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwitmentorsoft.id
  }

  tags = var.tags
  depends_on = [
    aws_internet_gateway.igwitmentorsoft
  ]
}

resource "aws_route_table_association" "rtta_public_itmentorsoft" {
  subnet_id      = aws_subnet.sbnpublic[0].id
  route_table_id = aws_route_table.rttpublic_itmentorsoft.id
  depends_on = [
    aws_subnet.sbnpublic,
    aws_route_table.rttpublic_itmentorsoft
  ]
}

resource "aws_route_table" "rttprivate_app_itmentorsoft" {
  vpc_id = aws_vpc.vpcitmentorsoft.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natitmentorsoft[0].id
  }

  tags = var.tags
  depends_on = [
    aws_nat_gateway.natitmentorsoft
  ]
}

resource "aws_route_table_association" "rtta_private_app_itmentorsoft" {
  subnet_id      = aws_subnet.sbnapp[0].id
  route_table_id = aws_route_table.rttprivate_app_itmentorsoft.id
  depends_on = [
    aws_subnet.sbnapp,
    aws_route_table.rttprivate_app_itmentorsoft
  ]
}

resource "aws_route_table" "rttprivate_db_itmentorsoft" {
  vpc_id = aws_vpc.vpcitmentorsoft.id

  tags = var.tags
}

resource "aws_route_table_association" "rtta_private_db_itmentorsoft" {
  subnet_id      = aws_subnet.sbndb[0].id
  route_table_id = aws_route_table.rttprivate_db_itmentorsoft.id
  depends_on = [
    aws_subnet.sbndb,
    aws_route_table.rttprivate_db_itmentorsoft
  ]
}

output "vpc_id" { value = aws_vpc.vpcitmentorsoft.id }
output "vpc_cidr" { value = aws_vpc.vpcitmentorsoft.cidr_block }
output "app_subnet_ids" { value = aws_subnet.sbnapp[*].id }
output "database_subnet_ids" { value = aws_subnet.sbndb[*].id }
output "public_subnet_ids" { value = aws_subnet.sbnpublic[*].id }

