data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_dynamodb_table" "audit" {
  name         = "${terraform.workspace}-${var.project}-AuditLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption { enabled = true }
}

resource "aws_iam_role" "lambda" {
  name               = "${terraform.workspace}-${var.project}-audit-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = var.audit_queue_arn
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.audit.arn
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.root}/lambda/audit_consumer/lambda_function.py"
  output_path = "${path.root}/.terraform/audit_consumer.zip"
}

resource "aws_lambda_function" "consumer" {
  function_name    = "${terraform.workspace}-${var.project}-audit-consumer"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      AUDIT_TABLE_NAME = aws_dynamodb_table.audit.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.audit_queue_arn
  function_name    = aws_lambda_function.consumer.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.consumer.function_name}"
  retention_in_days = 30
}

output "audit_table_name" { value = aws_dynamodb_table.audit.name }
output "lambda_name" { value = aws_lambda_function.consumer.function_name }
