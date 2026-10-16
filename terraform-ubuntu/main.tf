terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Owner      = var.owner_tag
    Env        = var.env_tag
    ts_creator = var.ts_creator
    ts_team    = var.ts_team
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Reuse the shared VPC and subnet
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "${var.name_prefix}-sg-ubuntu"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "Shipping Express website (adt-service-a) from my IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "Spring Boot apps between hosts in this SG"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-sg-ubuntu"
  })
}

resource "aws_instance" "main" {
  for_each = toset(var.instance_names)

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = data.aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_size
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.name_prefix}-${each.key}-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}
