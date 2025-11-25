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


module "lambda_iam" {
  source = "./modules/lambda_iam"

  lambda_project_name = var.project_name
  lambda_environment = var.environment
  lambda_handler = "app.lambda_handler"
  lambda_function_name = "${var.project_name}-fetcher"
  lambda_aws_region = var.aws_region
  
  dynamodb_table_name = module.dynamodb.dynamodb_table_name
  dynamodb_table_arn  = module.dynamodb.dynamodb_table_arn

}

