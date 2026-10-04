output "ecr_image_api_url" {
  value = module.ecr.ecr_image_api
}

output "ecr_image_evaluator_url" {
  value = module.ecr.ecr_image_evaluator
}

output "ecr_image_notifier_url" {
  value = module.ecr.ecr_image_notifier
}

output "evaluation_queue_url" {
  value = module.messaging.evaluation_queue_url
}

output "notification_queue_url" {
  value = module.messaging.notification_queue_url
}

output "audit_queue_url" {
  value = module.messaging.audit_queue_url
}

output "github_actions_role_arn" {
  value = module.ecr.github_actions_role_arn
}
