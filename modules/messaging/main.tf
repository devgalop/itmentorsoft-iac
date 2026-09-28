
resource "aws_sqs_queue" "dlq" {
  for_each = toset(var.queues)

  name                      = "${terraform.workspace}-${var.project}-${each.value}-dlq"
  message_retention_seconds = 259200
  sqs_managed_sse_enabled  = true

  tags = var.tags
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

  tags = var.tags
}

output "evaluation_queue_url" { value = aws_sqs_queue.queue["qualify"].url }
output "classification_queue_url" { value = aws_sqs_queue.queue["classify"].url }
output "classification_queue_arn" { value = aws_sqs_queue.queue["classify"].arn }
output "notification_queue_url" { value = aws_sqs_queue.queue["notify"].url }
output "audit_queue_url" { value = aws_sqs_queue.queue["audit"].url }
output "evaluation_queue_arn" { value = aws_sqs_queue.queue["qualify"].arn }
output "notification_queue_arn" { value = aws_sqs_queue.queue["notify"].arn }
output "audit_queue_arn" { value = aws_sqs_queue.queue["audit"].arn }