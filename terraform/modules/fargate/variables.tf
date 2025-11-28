variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "ecr_repo_name" {
  description = "Name for the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Image tag to deploy (e.g. latest)"
  type        = string
  default     = "latest"
}

variable "container_name" {
  description = "Container name inside task"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8501
}

variable "cpu" {
  description = "Task cpu"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Task memory (MiB)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Number of Fargate tasks to run"
  type        = number
  default     = 1
}

variable "subnets" {
  description = "List of subnet ids for the service (awsvpc)"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group ids to attach to the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign public IP to tasks"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for logs and ECR"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for the app to access"
  type        = string
}

variable "container_environment_variables" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}
