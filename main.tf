
provider "aws" {
  region = var.region
  access_key = "ASIAZ6D4PINXRK5KOIOO"
  secret_key = "Z+wCTCQp6Eb4FK2Ure9R46ZHOBmF/thHnt4OsnWts"
  token = "IQoJb3JpZ2luX2VjEHAaCXVzLXdlc3QtMiJIMEYCIQDd35kJdQ4ATYrmhngI/+NXSXQIGaqQ+bwFXx7lxxgQRgIhAItxnF347tmvR/lvntgVUqxNAnnsRLzJW+iqcb4W2kOTKrsCCMn//////////wEQARoMNjgzMTYwODQ3MjE1IgxIjvv/dHJVND7329wqjwIqRO8NO3iz5j4HZWZJUaCRGIX6fO4VTdv2pZH1KsWhuLjv467PVLf1fjYGNGJG2oABhVZcUbCyZZM09q1poj8SJzdv1KjuO3kmAPhqCfTQWd4eUcZq6CU1LJhLoBCUL8BCKe07Vh1X4uR2pj7cjoAynMNJcYa8R5B600O0eY/nm1wGTf+nxSECaPeBYLV5m028JaE+qeGtY8f09TeacSuUw/bAhCslLDgn/5UNdXhv4eeUiMWlKW0eYIY52p6DwFZ4RRZRPzDSkXTnQwZn5jhHMpAOoXDDVHaPEplk2qSGjNpmyucTfGWWw2I053iKDIofL9ZzEXlOxX0U4h0RNxwv0nMPOi8RL8pP6RfggBUNMOnk5bEGOpwBDIBwBKKocpXIEOCEVkKwm42eyuEpLQ6WHTBwH9uTFuHXXh1Y8O4fRWca/pTns9sSQWcmp7r0rwQGly2w++1xKZosuUCG3cEYRexUmtLEei4n4aS/I7HWQKuVyWVRM7XMi0C9bZdZO3uMNeGhzSu5qAHS7mfIqW3rfOOlyBpBkSN4evDjTrIyH8TeHXMoHaXi3qonCuReZFsPg+nU"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# TODO - Verificar se precisar criar manualmente essas VPC
module "vpc" { 
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                 = "tech-challenger-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  #   public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]

  create_database_subnet_group = true

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

resource "aws_db_parameter_group" "tech-challenger-db-parameter-group" {
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
  engine_version         = "14"
  username               = "postgres"
  password               = var.db_password # TODO - perguntar ao chat gpt de onde vem
  db_subnet_group_name   = aws_db_subnet_group.tech-challenger-db-subnet-group.name
  vpc_security_group_ids = [module.security_group.security_group_id]
  parameter_group_name   = aws_db_parameter_group.tech-challenger-db-parameter-group.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "tech-challenger"
  description = "Complete PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

}