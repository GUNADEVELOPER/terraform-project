terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "MY-PUBSUB"
  }
}
resource "aws_subnet" "pvtsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "MY-PVTSUB"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MY-IGW"
  }
}
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "MY-PUBRT"
  }
resource "aws_route_table_association" "pubassoc" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}
}
resource "aws_eip" "eip" {
  vpc      = true
}
data "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.pubsub.id
  tags = {
    Name = "MY-NAT"
  }
}
resource "aws_route_table" "pvtrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mynat.id
  }
  tags = {
    Name = "example"
  }
}
resource "aws_route_table_association" "pvtassoc" {
  subnet_id      = aws_subnet.pvtsub.id
  route_table_id = aws_route_table.pvtrt.id
}
resource "aws_security_group" "pubsg" {
  name        = "PUBSG"
  description = "PUBSG"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "pubsg"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
ingress {
    description      = "pubsg"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PUBSG"
  }
}
resource "aws_security_group" "pvtsg" {
  name        = "PVTSG"
  description = "PVTSG"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "pvtsg"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
ingress {
    description      = "pvtsg"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PVTSG"
  }
}
resource "aws_instance" "public" {
  ami           = "ami-07d3a50bd29811cd1"
  instance_type = "t2.micro"
  subnet_id                    = aws_subnet.pubsub.id
  vpc_security_group_ids       = [aws_security_group.pubsg.id]
  key_name                     = "249262ppk"
  associate_public_ip_address  = true

  tags = {
    Name = "Public"
  }
}
resource "aws_instance" "private" {
  ami           = "ami-07d3a50bd29811cd1"
  instance_type = "t2.micro"
  subnet_id                    = aws_subnet.pvtsub.id
  vpc_security_group_ids       = [aws_security_group.pvtsg.id]
  key_name                     = "249262ppk"

  tags = {
    Name = "Private"
  }
}