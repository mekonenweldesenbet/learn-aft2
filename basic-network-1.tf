# provider.tf
provider "aws" {
  alias  = "account1"
  region = "us-east-1" # Update with the region of account 1
  # Use Control Tower managed credentials if available for account 1
  # Omit access_key and secret_key
}



provider "aws" {
  alias  = "account2"
  region = "us-east-1" # Update with the region of account 2
  # Use Control Tower managed credentials if available for account 2
  # Omit access_key and secret_key
}

# variables.tf
variable "account1_vpc_cidr_block" {
  default = "10.0.0.0/16" # Update with your desired VPC CIDR block for account 1
}

variable "account2_vpc_cidr_block" {
  default = "10.1.0.0/16" # Update with your desired VPC CIDR block for account 2
}

# Define other variables as needed for subnet CIDR blocks, etc.

# main.tf
# Create VPCs in Account 1
provider "aws" {
  alias = "account1"
}

resource "aws_vpc" "vpc_account1" {
  cidr_block = var.account1_vpc_cidr_block
  provider   = aws.account1

  tags = {
    Name = "VPC-Account1"
  }
}

# Create Subnets in Account 1
resource "aws_subnet" "subnet_account1" {
  count             = 2
  vpc_id            = aws_vpc.vpc_account1.id
  cidr_block        = cidrsubnet(var.account1_vpc_cidr_block, 4, count.index)
  availability_zone = "us-east-1a" # Update with your desired availability zone

  tags = {
    Name = "Subnet-Account1-${count.index}"
  }
}

# Create Internet Gateway in Account 1
resource "aws_internet_gateway" "igw_account1" {
  vpc_id = aws_vpc.vpc_account1.id

  tags = {
    Name = "IGW-Account1"
  }
}

# Create NAT Gateway in Account 1
resource "aws_nat_gateway" "nat_gateway_account1" {
  allocation_id = aws_eip.eip_account1.id
  subnet_id     = aws_subnet.subnet_account1[0].id # Choose one of the public subnets

  tags = {
    Name = "NAT-Gateway-Account1"
  }
}

# Create Elastic IP for NAT Gateway in Account 1
resource "aws_eip" "eip_account1" {
  vpc = true

  tags = {
    Name = "EIP-Account1"
  }
}

# Create Transit Gateway in Account 1
resource "aws_ec2_transit_gateway" "transit_gateway_account1" {
  description = "Transit Gateway Account 1"

  tags = {
    Name = "Transit-Gateway-Account1"
  }
}

# Attach VPC to Transit Gateway in Account 1
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment_account1" {
  subnet_ids         = [aws_subnet.subnet_account1[0].id] # Choose a subnet
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway_account1.id
  vpc_id             = aws_vpc.vpc_account1.id
}

# Create Security Group in Account 1
resource "aws_security_group" "security_group_account1" {
  vpc_id = aws_vpc.vpc_account1.id

  tags = {
    Name = "Security-Group-Account1"
  }
}

# Define necessary security group rules as needed

# Create Route Table and Association for Public Subnets in Account 1
resource "aws_route_table" "route_table_public_account1" {
  vpc_id = aws_vpc.vpc_account1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_account1.id
  }

  tags = {
    Name = "Route-Table-Public-Account1"
  }
}

resource "aws_route_table_association" "route_table_association_public_account1" {
  for_each      = aws_subnet.subnet_account1
  subnet_id     = each.value.id
  route_table_id = aws_route_table.route_table_public_account1.id
}

# Create Route Table and Association for Private Subnets in Account 1
resource "aws_route_table" "route_table_private_account1" {
  vpc_id = aws_vpc.vpc_account1.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_account1.id
  }

  tags = {
    Name = "Route-Table-Private-Account1"
  }
}

resource "aws_route_table_association" "route_table_association_private_account1" {
  for_each      = aws_subnet.subnet_account1
  subnet_id     = each.value.id
  route_table_id = aws_route_table.route_table_private_account1.id
}

# Repeat the same pattern for resources in Account 2 by changing account numbers and updating resource names, tags, and associations accordingly.
