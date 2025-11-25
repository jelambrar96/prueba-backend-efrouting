variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "dynamodb_environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "dynamodb_aws_region" {
  description = "AWS region"
  type        = string
}


variable "dynamodb_project_name" {
  description = "Project name for tagging"
  type        = string
}
