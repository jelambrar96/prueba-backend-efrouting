variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}


variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}


variable "project_name" {
  description = "jspx"
  type        = string
  default     = "spacex-dashboard"
}


variable "quicksight_user_arn" {
  description = "ARN of the QuickSight user to grant access to the data source"
  type        = string
  default     = "quicksightspacexuser"
}

