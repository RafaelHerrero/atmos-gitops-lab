# Terraform version and provider requirements for k3d cluster

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    # Null provider for executing local commands
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # Local provider for file operations
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }

    # External provider for running external programs
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
