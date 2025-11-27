# ========================
# API Gateway for Manual Lambda Invocation
# ========================

resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "${var.lambda_project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

# Integration between API Gateway and Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  payload_format_version = "2.0"
  integration_uri = "arn:aws:apigateway:${var.lambda_aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.spacex_lambda.arn}/invocations"
}

# Route for manual invocation: POST /invoke
resource "aws_apigatewayv2_route" "invoke_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /invoke"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for health check: GET /health
resource "aws_apigatewayv2_route" "health_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Stage for deployment
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# ========================
# IAM Role for API Gateway
# ========================

resource "aws_iam_role" "api_gateway_role" {
  name = "${var.lambda_project_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spacex_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# Policy for API Gateway to invoke Lambda
resource "aws_iam_role_policy" "api_gateway_invoke_policy" {
  name = "${var.lambda_project_name}-api-invoke-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.spacex_lambda.arn,
          "${aws_lambda_function.spacex_lambda.arn}:*"
        ]
      }
    ]
  })
}
