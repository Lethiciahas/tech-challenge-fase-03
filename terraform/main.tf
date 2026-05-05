terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "feature-flag-dev-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "feature-flag-dev-tflock"
    encrypt        = true
    profile        = "devops"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "tfstate_backend" {
  source = "./modules/tfstate-backend"

  project_name = var.project_name
  environment  = var.environment
}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  repositories = var.ecr_repositories
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_instances       = var.rds_instances
}

module "elasticache" {
  source = "./modules/elasticache"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.elasticache_node_type
  num_cache_nodes    = var.elasticache_num_nodes
}

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
  table_name   = var.dynamodb_table_name
}

module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  queue_name   = var.sqs_queue_name
}

module "ec2_k8s" {
  source = "./modules/ec2-k8s"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  public_subnet_id        = module.vpc.public_subnet_ids[0]
  private_subnet_ids      = module.vpc.private_subnet_ids
  instance_type           = var.k8s_instance_type
  key_name                = var.ssh_key_name
  rds_security_group_id   = module.rds.security_group_id
  redis_security_group_id = module.elasticache.security_group_id
  allowed_ssh_cidr        = var.allowed_ssh_cidr
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ec2_instance_id   = module.ec2_k8s.instance_id
}

module "cicd" {
  source = "./modules/cicd"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  github_repo     = var.github_repo
  github_branch   = var.github_branch
  ecr_repositories = module.ecr.repository_urls
  services        = var.ecr_repositories
}
