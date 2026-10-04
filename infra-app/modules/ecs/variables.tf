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

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "alb_security_group" {
  description = "The security group for the Application Load Balancer"
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets for the Application Load Balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "api_container_port" {
  description = "The port on which the API container listens"
  type        = number
}

variable "db_host" {
  description = "The hostname of the database"
  type        = string
}

variable "db_port" {
  description = "The port of the database"
  type        = number
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
}

variable "cache_endpoint" {
  description = "The endpoint for the cache service"
  type        = string
}

variable "evaluation_queue_url" {
  description = "The URL of the evaluation SQS queue"
  type        = string
}

variable "notification_queue_url" {
  description = "The URL of the notification SQS queue"
  type        = string
}

variable "audit_queue_url" {
  description = "The URL of the audit SQS queue"
  type        = string
}

variable "worker_desired_count" {
  description = "The desired number of worker tasks (evaluator and notifier)"
  type        = number
}

variable "api_cpu" {
  description = "The CPU units for the API container"
  type        = number
}

variable "api_memory" {
  description = "The memory (in MiB) for the API container"
  type        = number
}

variable "api_image" {
  description = "The Docker image for the API container"
  type        = string
}

variable "worker_cpu" {
  description = "The CPU units for the worker containers (evaluator and notifier)"
  type        = number
}

variable "worker_memory" {
  description = "The memory (in MiB) for the worker containers (evaluator and notifier)"
  type        = number
}

variable "evaluator_image" {
  description = "The Docker image for the evaluator container"
  type        = string
}

variable "notifier_image" {
  description = "The Docker image for the notifier container"
  type        = string
}

variable "api_min_capacity" {
  description = "The minimum number of API tasks"
  type        = number
}

variable "api_max_capacity" {
  description = "The maximum number of API tasks"
  type        = number
}

variable "ecs_tasks_security_group" {
  description = "The security group for the ECS tasks"
  type        = string
}
