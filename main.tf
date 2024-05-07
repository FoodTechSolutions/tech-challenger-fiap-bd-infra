
provider "aws" {
  region = var.region
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  # token = var.AWS_SECURITY_TOKEN
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