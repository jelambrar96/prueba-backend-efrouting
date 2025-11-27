variable "build_script_path" {
  description = "Path to the build_and_push.sh script"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL (without tag)"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "force_rebuild" {
  description = "Force rebuild of image (change this to trigger rebuild)"
  type        = string
  default     = "no"
}
