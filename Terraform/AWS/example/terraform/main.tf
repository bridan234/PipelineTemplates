# Example Terraform Configuration for Pipeline Testing
#
# This uses the 'null' provider - no real infrastructure is created.
# The pipeline can validate and plan without any cloud credentials.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Using local backend - no remote state required for testing
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Generate a random ID to simulate resource creation
resource "random_id" "example" {
  byte_length = 8
}

# Null resource to simulate infrastructure
resource "null_resource" "example" {
  triggers = {
    environment  = var.environment
    project_name = var.project_name
    random_id    = random_id.example.hex
  }

  provisioner "local-exec" {
    command = "echo 'Simulated resource for ${var.project_name} in ${var.environment} environment'"
  }
}

# Another null resource to show multiple resources in plan
resource "null_resource" "app_server" {
  count = var.instance_count

  triggers = {
    instance_number = count.index
    environment     = var.environment
  }

  provisioner "local-exec" {
    command = "echo 'Simulated app server ${count.index + 1} of ${var.instance_count}'"
  }
}

# Simulate a database resource
resource "null_resource" "database" {
  count = var.create_database ? 1 : 0

  triggers = {
    db_name     = "${var.project_name}-${var.environment}-db"
    environment = var.environment
  }

  provisioner "local-exec" {
    command = "echo 'Simulated database: ${var.project_name}-${var.environment}-db'"
  }
}
