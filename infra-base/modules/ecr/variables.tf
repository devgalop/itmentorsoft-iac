variable "github_repositories" {
  description = "List of GitHub repositories allowed to assume the role"
  type        = list(string)
  default = [
    "repo:devgalop/itmentorsoft-back-api:*",
    "repo:devgalop/itmentorsoft-back-worker-evaluator:*",
    "repo:devgalop/itmentorsoft-back-worker-notificator:*"
  ]
}

variable "ecr_repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default = [
    "itmentorsoft-back-api",
    "itmentorsoft-back-worker-evaluator",
    "itmentorsoft-back-worker-notificator"
  ]
}

variable "ecr_push_actions" {
  description = "List of actions allowed for pushing to ECR in the IAM policy document"
  type        = list(string)
  default = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:CompleteLayerUpload",
    "ecr:InitiateLayerUpload",
    "ecr:PutImage",
    "ecr:UploadLayerPart"
  ]
}

variable "ecr_authorization_actions" {
  description = "List of actions allowed for ECR authorization in the IAM policy document"
  type        = list(string)
  default = [
    "ecr:GetAuthorizationToken"
  ]
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