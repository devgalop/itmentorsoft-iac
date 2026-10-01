variable "project" {
  description = "The project name to be used in resource naming"
  type        = string
}

variable "owner" {
  description = "The owner of the resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}

variable "audit_queue_arn" {
  description = "The ARN of the SQS queue for audit messages"
  type        = string
}