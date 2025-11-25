terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "efrouting"
}


module "dynamodb" {
  source = "./modules/dynamodb"

  dynamodb_table_name  = "${var.project_name}-launches"
  dynamodb_environment = var.environment
  dynamodb_aws_region  = var.aws_region
  dynamodb_project_name = var.project_name
}
