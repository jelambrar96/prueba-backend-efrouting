output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.spacex_lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.spacex_lambda.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.lambda_schedule.arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL for manual Lambda invocation"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/invoke"
}

output "api_gateway_health_endpoint" {
  description = "API Gateway health check endpoint"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/health"
}

output "api_gateway_url" {
  description = "Base API Gateway URL"
  value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}
