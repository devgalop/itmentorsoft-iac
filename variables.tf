
variable "project" {
  description = "The name of the project"
  type        = string
}

variable "owner" {
  description = "The owner of the resources"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
}

variable "app_subnets" {
  description = "List of application subnets"
  type        = list(string)
}

variable "db_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

variable "queues" {
  description = "List of SQS queues to create including their dead-letter queues"
  type        = list(string)
}

variable "api_port" {
  description = "The port on which the API will listen"
  type        = number
}

variable "db_scheduler_start_time" {
  description = "The start time for the RDS instance scheduler in cron format"
  type        = string
}

variable "db_scheduler_stop_time" {
  description = "The stop time for the RDS instance scheduler in cron format"
  type        = string
}

variable "db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "username" {
  description = "The master username for the RDS database"
  type        = string
}

variable "password" {
  description = "The master password for the RDS database"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS database"
  type        = string
}

variable "db_engine_version" {
  description = "The engine version for the RDS database"
  type        = string
}

variable "multi_az" {
  description = "Whether the RDS database should be multi-AZ"
  type        = bool
}

variable "cache_engine_version" {
  description = "The engine version for the ElastiCache cluster"
  type        = string
}

variable "cache_node_type" {
  description = "The node type for the ElastiCache cluster"
  type        = string
}