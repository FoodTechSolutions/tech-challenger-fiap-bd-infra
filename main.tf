terraform {
  cloud {
    organization = "tech-challenger"

    workspaces {
      name = "tech-challenger-fiap-bd-infra"
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
  subnet_ids = ["subnet-12345678", "subnet-87654321"] # Substitua pelos IDs das suas sub-redes

  tags = {
    Name = "tech-challenger-db-subnet-group"
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
  engine_version         = "12.5" # Versão corrigida
  username               = "postgres"
  password               = var.db_password # TODO - perguntar ao chat gpt de onde vem
  db_subnet_group_name   = aws_db_subnet_group.tech-challenger-db-subnet-group.name
  vpc_security_group_ids = [module.vpc.default_security_group_id] # Adicione a referência ao grupo de segurança padrão da VPC
  parameter_group_name   = aws_db_parameter_group.tech-challenger-db-parameter-group.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
}