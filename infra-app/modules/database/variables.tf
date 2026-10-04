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

variable "db_engine_version" {
  description = "The version of the database engine"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class of the database"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "username" {
  description = "The username for the database"
  type        = string
}

variable "password" {
  description = "The password for the database"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
}

variable "security_group_id" {
  description = "The security group ID for the database"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs for the database subnet group"
  type        = list(string)
}

variable "db_scheduler_start_time" {
  description = "The start time for the RDS scheduler in cron format"
  type        = string
}

variable "db_scheduler_stop_time" {
  description = "The stop time for the RDS scheduler in cron format"
  type        = string
}