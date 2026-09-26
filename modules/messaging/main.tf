
resource "aws_sqs_queue" "dlq" {
  for_each = toset(var.queues)

  name                      = "${terraform.workspace}-${var.project}-${each.value}-dlq"
  message_retention_seconds = 259200
  sqs_managed_sse_enabled  = true

  tags = {
    Name = "${terraform.workspace}-queue-${var.project}-${each.value}-dlq"
    Environment = terraform.workspace
    Owner = var.owner
  }
}

resource "aws_sqs_queue" "queue" {
  for_each = toset(var.queues)

  name                       = "${terraform.workspace}-queue-${var.project}-${each.value}"
  visibility_timeout_seconds = 120
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled   = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${terraform.workspace}-queue-${var.project}-${each.value}"
    Environment = terraform.workspace
    Owner = var.owner
  }
}