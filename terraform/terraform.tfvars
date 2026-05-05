aws_region     = "us-east-1"
aws_profile    = "devops"
aws_account_id = "964177143569"

project_name = "feature-flag"
environment  = "dev"

vpc_cidr = "10.0.0.0/16"

ecr_repositories = [
  "auth-service",
  "flag-service",
  "targeting-service",
  "evaluation-service",
  "analytics-service"
]

rds_instances = {
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

elasticache_node_type = "cache.t3.micro"
elasticache_num_nodes = 1

dynamodb_table_name = "analytics-events"
sqs_queue_name      = "evaluation-events"

k8s_instance_type = "t3.medium"
ssh_key_name      = "feature-flag-k8s-key"
allowed_ssh_cidr  = ["0.0.0.0/0"]

github_repo   = "owner/feature-flag"
github_branch = "main"
