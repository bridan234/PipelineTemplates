# Variables for the example Terraform configuration

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pipeline-test"
}

variable "instance_count" {
  description = "Number of simulated app server instances"
  type        = number
  default     = 2
}

variable "create_database" {
  description = "Whether to create the simulated database"
  type        = bool
  default     = true
}
