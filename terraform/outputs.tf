output "ecr_repositories" {
  value = module.ecr.repository_urls
}

output "rds_endpoints" {
  value     = module.rds.db_endpoints
  sensitive = true
}

output "rds_credentials" {
  value     = module.rds.db_credentials
  sensitive = true
}

output "elasticache_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "sqs_queue_arn" {
  value = module.sqs.queue_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "k8s_node_public_ip" {
  value = module.ec2_k8s.public_ip
}

output "k8s_node_instance_id" {
  value = module.ec2_k8s.instance_id
}

output "tfstate_bucket" {
  value = module.tfstate_backend.bucket_name
}

output "cicd_pipeline_names" {
  value = module.cicd.pipeline_names
}
