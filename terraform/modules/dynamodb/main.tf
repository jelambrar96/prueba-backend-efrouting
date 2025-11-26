resource "aws_dynamodb_table" "spacex_launches" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"   # On-demand
  # hash_key       = "launchpad_id"
  hash_key       = "id"
  range_key      = "launch_date"
  
  point_in_time_recovery {
    enabled = true
  }

  # attribute {
  #   name = "launchpad_id"
  #   type = "S"
  # }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "launch_date"
    # Lambda returns ISO8601 date strings (e.g. 2025-11-26T12:34:56+00:00)
    # Keep this attribute as a string so it matches the function output and
    # sorts lexicographically for range-key queries.
    type = "S"
  }

  # Server-side encryption enabled by default (AWS owned key)
  tags = {
    Environment = var.dynamodb_environment
    Project     = var.dynamodb_project_name
  }

  # Optional: enable TTL on 'expire_at' if you want items to auto-expire
  # ttl {
  #   attribute_name = "expire_at"
  #   enabled        = false
  # }
}

