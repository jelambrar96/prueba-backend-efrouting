output "dynamodb_table_name" {
  value = aws_dynamodb_table.spacex_launches.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.spacex_launches.arn
}

