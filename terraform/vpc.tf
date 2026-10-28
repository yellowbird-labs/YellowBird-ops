# ==============================================================================
# Virtual Private Cloud (VPC)
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Import block: Binds Terraform to your existing live VPC
import {
  to = aws_vpc.main
  id = "vpc-030782d59440cd699"
}

# ==============================================================================
# Internet Gateway (IGW)
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

import {
  to = aws_internet_gateway.main
  id = "igw-04235f532e15b7227"
}

# ==============================================================================
# Public Subnets (Multi-AZ for ALB Ingress)
# ==============================================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public1-us-east-1a"
  }
}

import {
  to = aws_subnet.public_1
  id = "subnet-01629aa1bd333b81a"
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public2-us-east-1b"
  }
}

import {
  to = aws_subnet.public_2
  id = "subnet-05caac013b301a4d3"
}

# ==============================================================================
# Private Subnets (Reserved for Internal Tasks)
# ==============================================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.project_name}-subnet-private1-us-east-1a"
  }
}

import {
  to = aws_subnet.private_1
  id = "subnet-0d5571e82b1185ced"
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.project_name}-subnet-private2-us-east-1b"
  }
}

import {
  to = aws_subnet.private_2
  id = "subnet-04580c5b96c624754"
}

# ==============================================================================
# Public Route Table & Associations
# ==============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rtb-public"
  }
}

import {
  to = aws_route_table.public
  id = "rtb-014a1ce82ad365c54"
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# S3 Gateway VPC Endpoint ($0.00 / mo Cost Saver)
# ==============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    "rtb-0a3b73d73ebe499b4",
    "rtb-0ff531d461bd95385"
  ]

  tags = {
    Name = "${var.project_name}-vpce-s3"
  }
}

import {
  to = aws_vpc_endpoint.s3
  id = "vpce-05ad6261930113489"
}