# VPC

resource "aws_vpc" "principal_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC Principal"
  }
}

# Public Subnet

resource "aws_subnet" "principal_public_subnet_1" {
  availability_zone    = "us-east-1a"
  cidr_block           = "10.0.0.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "principal_public_subnet_2" {
  availability_zone    = "us-east-1b"
  cidr_block           = "10.0.16.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Public Subnet 2"
  }
}

# Private subnet

resource "aws_subnet" "principal_private_subnet_1" {
  availability_zone    = "us-east-1a"
  cidr_block           = "10.0.32.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "principal_private_subnet_2" {
  availability_zone    = "us-east-1b"
  cidr_block           = "10.0.48.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_subnet" "principal_private_subnet_3" {
  availability_zone    = "us-east-1a"
  cidr_block           = "10.0.64.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Private Subnet 3"
  }
}

resource "aws_subnet" "principal_private_subnet_4" {
  availability_zone    = "us-east-1b"
  cidr_block           = "10.0.80.0/20"
  vpc_id               = aws_vpc.principal_vpc.id

  tags = {
    Name = "Private Subnet 4"
  }
}

# Internet gateway

resource "aws_internet_gateway" "principal_ig" {
  vpc_id = aws_vpc.principal_vpc.id

  tags = {
    Name = "Principal Internet Gateway"
  }
}

# Route Table

resource "aws_route_table" "rt_public_subnet" {
  vpc_id = aws_vpc.principal_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal_ig.id
  }

  route {
    cidr_block = aws_vpc.principal_vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "association_public_1" {
  subnet_id      = aws_subnet.principal_public_subnet_1.id
  route_table_id = aws_route_table.rt_public_subnet.id
}

resource "aws_route_table_association" "association_public_2" {
  subnet_id      = aws_subnet.principal_public_subnet_2.id
  route_table_id = aws_route_table.rt_public_subnet.id
}

resource "aws_route_table" "rt_private_subnet_1" {
  vpc_id = aws_vpc.principal_vpc.id

  route {
    cidr_block = aws_vpc.principal_vpc.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_ng.id
  }

  tags = {
    Name = "Private Route Table 1"
  }
}

resource "aws_route_table_association" "association_private_1" {
  subnet_id      = aws_subnet.principal_private_subnet_1.id
  route_table_id = aws_route_table.rt_private_subnet_1.id
}

resource "aws_route_table" "rt_private_subnet_2" {
  vpc_id = aws_vpc.principal_vpc.id

  route {
    cidr_block = aws_vpc.principal_vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "Private Route Table 2"
  }
}

resource "aws_route_table_association" "association_private_2" {
  subnet_id      = aws_subnet.principal_private_subnet_2.id
  route_table_id = aws_route_table.rt_private_subnet_2.id
}

resource "aws_route_table" "rt_private_subnet_3" {
  vpc_id = aws_vpc.principal_vpc.id

  route {
    cidr_block = aws_vpc.principal_vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "Private Route Table 3"
  }
}

resource "aws_route_table_association" "association_private_3" {
  subnet_id      = aws_subnet.principal_private_subnet_3.id
  route_table_id = aws_route_table.rt_private_subnet_3.id
}

resource "aws_route_table" "rt_private_subnet_4" {
  vpc_id = aws_vpc.principal_vpc.id

  route {
    cidr_block = aws_vpc.principal_vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "Private Route Table 4"
  }
}

resource "aws_route_table_association" "association_private_4" {
  subnet_id      = aws_subnet.principal_private_subnet_4.id
  route_table_id = aws_route_table.rt_private_subnet_4.id
}

# NAT Gateway

resource "aws_eip" "eip_nat_gateway" {
  domain   = "vpc"
  network_border_group = "us-east-1"

  tags = {
    Name = "EIP Nat Gateway"
  }
}

resource "aws_nat_gateway" "public_ng" {
  allocation_id = aws_eip.eip_nat_gateway.id
  subnet_id     = aws_subnet.principal_public_subnet_1.id

  tags = {
    Name = "Public Nat Gateway"
  }

  depends_on = [aws_internet_gateway.principal_ig]
}

# EC2 instance

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.ssm_role.name
}

# public intance

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.principal_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public_instance" {
  ami                         = "ami-04b70fa74e45c3917"
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id                   = aws_subnet.principal_public_subnet_1.id

  tags = {
    Name = "SSM-Managed-Instance"
  }

  depends_on = [ aws_security_group.allow_ssh ]
}

# private instance

resource "aws_security_group" "allow_ssh_private" {
  name        = "allow_ssh_private"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.principal_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "private_instance" {
  ami                         = "ami-04b70fa74e45c3917"
  associate_public_ip_address = false
  availability_zone           = "us-east-1a"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_private.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id                   = aws_subnet.principal_private_subnet_1.id

  tags = {
    Name = "SSM-Managed-Instance"
  }

  depends_on = [ aws_security_group.allow_ssh_private ]
}