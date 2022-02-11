
output "secret_name" {
  description = "The name of the secret that was created"
  value       = local.secret_name
  depends_on  = [gitops_module.module]
}

output "name" {
  description = "The name of the module"
  value       = gitops_module.module.name
}

output "branch" {
  description = "The branch where the module config has been placed"
  value       = local.application_branch
  depends_on  = [gitops_module.module]
}

output "namespace" {
  description = "The namespace where the module will be deployed"
  value       = gitops_module.module.namespace
}

output "server_name" {
  description = "The server where the module will be deployed"
  value       = gitops_module.module.server_name
}

output "layer" {
  description = "The layer where the module is deployed"
  value       = gitops_module.module.layer
}

output "type" {
  description = "The type of module where the module is deployed"
  value       = gitops_module.module.type
}
