data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
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
