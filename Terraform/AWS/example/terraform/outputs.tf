# Outputs for the example Terraform configuration

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "random_id" {
  description = "Generated random ID"
  value       = random_id.example.hex
}

output "instance_count" {
  description = "Number of app server instances"
  value       = var.instance_count
}

output "database_created" {
  description = "Whether database was created"
  value       = var.create_database
}
