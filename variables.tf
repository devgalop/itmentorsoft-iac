
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
