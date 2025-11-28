resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_project_name}_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem"
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name   = "${var.dynamodb_table_name}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_dynamodb_access.json
}


resource "aws_iam_role_policy_attachment" "lambda_attach_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}


# Build Lambda deployment package with dependencies
resource "null_resource" "lambda_build" {
  triggers = {
    requirements_hash = filemd5("${path.module}/../../../compute/lambda/requirements.txt")
    app_hash          = filemd5("${path.module}/../../../compute/lambda/app.py")
    model_hash        = filemd5("${path.module}/../../../compute/lambda/model.py")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../../../compute/lambda/build.sh"
  }
}

# Create Lambda deployment package (already includes dependencies from build.sh)
data "archive_file" "lambda_zip" {
  type = "zip"
  # source_file = "${path.module}/../../../compute/lambda/lambda.zip"
  source_dir  = "${path.module}/../../../compute/lambda/build/package"
  output_path = "${path.module}/lambda_deployment.zip"

  depends_on = [null_resource.lambda_build]
}

resource "aws_lambda_function" "spacex_lambda" {
  function_name    = var.lambda_function_name
  handler          = var.lambda_handler
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 15

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      ENVIRONMENT    = var.lambda_environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_attach_dynamodb,
    data.archive_file.lambda_zip
  ]
}


# EventBridge rule to trigger Lambda at 01:00, 07:00, 13:00, and 19:00 UTC daily
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.lambda_project_name}-schedule"
  description         = "Trigger Lambda at 01:00, 07:00, 13:00, and 19:00 UTC"
  schedule_expression = "cron(0 1,7,13,19 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "SpaceXLambdaTarget"
  arn       = aws_lambda_function.spacex_lambda.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spacex_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

