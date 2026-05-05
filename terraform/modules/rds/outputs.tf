output "db_endpoints" {
  value = { for k, v in aws_db_instance.postgres : k => v.endpoint }
}

output "db_credentials" {
  value = { for k, v in aws_secretsmanager_secret.db_credentials : k => v.arn }
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
