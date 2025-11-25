variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "lambda_project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "lambda_environment" {
  description = "Lambda environment"
  type        = string
}

variable "lambda_aws_region" {
  description = "AWS region for Lambda"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
}
