# Data source for the existing IAM OIDC provider for GitHub Actions
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Get the AWS account ID of the current caller
data "aws_caller_identity" "current" {}

# Create an IAM policy document that allows GitHub Actions to assume a role
data "aws_iam_policy_document" "github_actions_assume_role" {

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

        identifiers = [
          data.aws_iam_openid_connect_provider.github.arn
        ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

    # Allow GitHub Actions workflows from the specified repositories to assume the role
      values = var.github_repositories
    }
  }
}

# Create an IAM role for GitHub Actions to access ECR
resource "aws_iam_role" "github_actions_ecr" {

  name = "GitHubActionsECRRole"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Create ECR repositories for the specified repository names
resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repository_names)

  name                 = each.key
  image_tag_mutability = "IMMUTABLE" # Ensure that image tags cannot be overwritten

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}


# Create lifecycle policies for the ECR repositories
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the newest 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

data "aws_iam_policy_document" "github_actions_ecr" {

  statement {
    sid    = "ECRAuthorization"
    effect = "Allow"

    actions = var.ecr_authorization_actions

    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"

    actions = var.ecr_push_actions

    resources = [
      for repository in aws_ecr_repository.this :
      repository.arn
    ]
  }
}

# Create an IAM policy for GitHub Actions to push to ECR
resource "aws_iam_policy" "github_actions_ecr" {

  name = "GitHubActionsECRPushPolicy"

  policy = data.aws_iam_policy_document.github_actions_ecr.json
}

# Attach the IAM policy to the GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {

  role = aws_iam_role.github_actions_ecr.name

  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Outputs for the GitHub Actions role ARN and ECR repository URLs
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr.arn
}

# Output for the ECR repository URLs
output "ecr_repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.repository_url
  }
}



