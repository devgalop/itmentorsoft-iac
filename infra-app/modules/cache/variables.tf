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

variable "subnet_ids" {
  description = "A list of subnet IDs for the cache subnet group"
  type        = list(string)
}

variable "engine_version" {
  description = "The version of the cache engine"
  type        = string
}

variable "node_type" {
  description = "The instance type for the cache nodes"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID to associate with the cache"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable multi-AZ for the cache replication group"
  type        = bool
}