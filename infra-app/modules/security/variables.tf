variable "project" {
  description = "The project name used in resource naming"
  type        = string
}

variable "owner" {
  description = "The owner of the resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "api_port" {
  description = "The port for the API"
  type        = number
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}