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

variable "private_subnet_ids" {
    description = "List of private subnet IDs for the VPC link"
    type = list(string)
}

variable "api_security_group" {
    description = "The security group ID for the API"
    type = string
}

variable "alb_listener_arn" {
    description = "The ARN of the ALB listener to integrate with the API"
    type = string
}