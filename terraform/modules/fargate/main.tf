locals {
  full_repo_name = var.ecr_repo_name
  task_family    = "${var.project_name}-task"

  # Default environment variables for Streamlit container
  default_env_vars = {
    DYNAMODB_TABLE_NAME       = var.dynamodb_table_name
    AWS_REGION                = var.aws_region
    STREAMLIT_SERVER_HEADLESS = "true"
    STREAMLIT_SERVER_PORT     = tostring(var.container_port)
    STREAMLIT_SERVER_ADDRESS  = "0.0.0.0"
    STREAMLIT_LOGGER_LEVEL    = "info"
  }

  # Merge default variables with user-provided overrides
  env_vars = merge(local.default_env_vars, var.container_environment_variables)
}

resource "aws_ecr_repository" "repo" {
  name                 = local.full_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${local.task_family}"
  retention_in_days = 14
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.project_name}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_attach" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Policy to allow task to read from DynamoDB
resource "aws_iam_policy" "task_dynamodb_policy" {
  name        = "${var.project_name}-dynamodb-read-policy"
  description = "Allow ECS task to read from DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_dynamodb_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_dynamodb_policy.arn
}

# Task definition using image from ECR
resource "aws_ecs_task_definition" "task" {
  family                   = local.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${aws_ecr_repository.repo.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for key, value in local.env_vars : {
          name  = key
          value = value
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.task_family
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  depends_on = [
    aws_iam_role_policy_attachment.task_execution_attach,
    aws_iam_role_policy_attachment.task_dynamodb_attach
  ]
}
