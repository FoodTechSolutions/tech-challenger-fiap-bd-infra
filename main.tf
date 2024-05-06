# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
terraform {
  cloud {
    organization = "tech-challenger"

    workspaces {
      name = "tech-challenger-tf"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {} # TODO - perguntar ao chat gpt

# TODO - Verificar se precisar criar manualmente essas VPC
module "vpc" { 
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "tech-challenger-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# TODO - Verificar se precisa criar manualmente
resource "aws_db_subnet_group" "tech-challenger-db-subnet-group" {
  name       = "tech-challenger-db-subnet-group"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "tech-challenger-db-subnet-group"
  }
}

# TODO - Verificar se precisa criar manualmente
resource "aws_security_group" "rds" {
  name   = "tech-challenger-rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tech-challenger-rds"
  }
}

resource "aws_db_parameter_group" "tasteease-db-parameter-group" {
  name   = "tech-challenger-db-parameter-group"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "tech-challenger-pgsql-rds-db" {
  identifier             = "tech-challenger-pgsql-rds-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "16.1"
  username               = "postgres"
  password               = var.db_password # TODO - perguntar ao chat gpt de onde vem
  db_subnet_group_name   = aws_db_subnet_group.tech-challenger-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.tech-challenger-db-parameter-group.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
}