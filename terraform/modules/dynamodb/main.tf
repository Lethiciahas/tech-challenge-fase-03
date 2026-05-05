resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.environment}-${var.table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_id"
  range_key      = "timestamp"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.table_name}"
    Environment = var.environment
  }
}
