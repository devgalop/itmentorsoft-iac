
variable "owner" {
  description = "The owner of the resources"
  type        = string
}

variable "project" {
  description = "The project name for the resources"
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

variable "public_subnets" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "app_subnets" {
  description = "The CIDR blocks for the application subnets"
  type        = list(string)
}

variable "db_subnets" {
  description = "The CIDR blocks for the database subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "The availability zones for the VPC"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}