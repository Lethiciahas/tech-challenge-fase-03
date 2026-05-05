output "bucket_name" {
  value = aws_s3_bucket.tfstate.id
}

output "bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tflock.name
}
