
variable "queues" {
  description = "List of SQS queues to create including their dead-letter queues"
  type        = list(string)
}

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
