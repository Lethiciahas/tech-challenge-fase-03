variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "devops"
}

variable "aws_account_id" {
  type    = string
  default = "964177143569"
}

variable "project_name" {
  type    = string
  default = "feature-flag"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ecr_repositories" {
  type = list(string)
  default = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]
}

variable "rds_instances" {
  type = map(object({
    allocated_storage = number
    engine_version    = string
    instance_class    = string
    db_name           = string
  }))
  default = {
    auth = {
      allocated_storage = 20
      engine_version    = "16.13"
      instance_class    = "db.t3.micro"
      db_name           = "authdb"
    }
    flag = {
      allocated_storage = 20
      engine_version    = "16.13"
      instance_class    = "db.t3.micro"
      db_name           = "flagdb"
    }
    targeting = {
      allocated_storage = 20
      engine_version    = "16.13"
      instance_class    = "db.t3.micro"
      db_name           = "targetingdb"
    }
  }
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "elasticache_num_nodes" {
  type    = number
  default = 1
}

variable "dynamodb_table_name" {
  type    = string
  default = "analytics-events"
}

variable "sqs_queue_name" {
  type    = string
  default = "evaluation-events"
}

variable "k8s_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ssh_key_name" {
  type    = string
  default = ""
}

variable "allowed_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "github_repo" {
  type    = string
  default = "Lethiciahas/tech-challenge-fase-03"
}

variable "github_branch" {
  type    = string
  default = "main"
}
