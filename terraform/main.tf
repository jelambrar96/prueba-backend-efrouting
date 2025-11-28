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
  region  = var.aws_region
  profile = "efrouting"
}

# Network infrastructure
module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  container_port       = 8501
  enable_nat_gateway   = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "dynamodb" {
  source = "./modules/dynamodb"

  dynamodb_table_name   = "${var.project_name}-launches"
  dynamodb_environment  = var.environment
  dynamodb_aws_region   = var.aws_region
  dynamodb_project_name = var.project_name
}


module "lambda_iam" {
  source = "./modules/lambda_iam"

  lambda_project_name  = var.project_name
  lambda_environment   = var.environment
  lambda_handler       = "app.lambda_handler"
  lambda_function_name = "${var.project_name}-fetcher"
  lambda_aws_region    = var.aws_region

  dynamodb_table_name = module.dynamodb.dynamodb_table_name
  dynamodb_table_arn  = module.dynamodb.dynamodb_table_arn

}


# Build and push Docker image to ECR before deploying Fargate service
module "docker_ecr_push" {
  source = "./modules/docker_ecr_push"

  build_script_path  = "${path.module}/../compute/streamlit/build_and_push.sh"
  aws_region         = var.aws_region
  ecr_repository_url = module.fargate.ecr_repository_url
  image_tag          = "latest"
  force_rebuild      = "no"

  depends_on = [module.fargate]
}

module "fargate" {
  source              = "./modules/fargate"
  project_name        = var.project_name
  ecr_repo_name       = "${var.project_name}-streamlit"
  image_tag           = "latest"
  container_name      = "streamlit"
  container_port      = 8501
  cpu                 = "512"
  memory              = "1024"
  desired_count       = 1
  aws_region          = var.aws_region
  dynamodb_table_name = module.dynamodb.dynamodb_table_name

  # Networking from the networking module
  subnets          = module.networking.public_subnet_ids
  security_groups  = [module.networking.fargate_security_group_id]
  assign_public_ip = true

  # Optional: Additional environment variables
  container_environment_variables = {
    # Add any additional env vars here if needed
  }

  depends_on = [module.networking]
}
