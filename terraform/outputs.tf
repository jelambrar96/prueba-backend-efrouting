# Network outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "fargate_security_group_id" {
  description = "Security group for Fargate"
  value       = module.networking.fargate_security_group_id
}

# DynamoDB outputs
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.dynamodb_table_arn
}

# Lambda outputs
output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda_iam.lambda_function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda_iam.lambda_function_arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint for manual Lambda invocation"
  value       = module.lambda_iam.api_gateway_endpoint
}

# Fargate outputs
output "ecr_repository_url" {
  description = "ECR repository URL for Streamlit"
  value       = module.fargate.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = "${var.project_name}-cluster"
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.fargate.ecs_service_name
}
