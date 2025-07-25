# terraform/versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"

  # Configure S3 backend for Terraform state
  backend "s3" {
    bucket         = "ojhashish-devops-project-terraform-state-2025-unique" # <--- REPLACE with YOUR UNIQUE BUCKET NAME
    key            = "devops-two-tier-app.tfstate" # Name of the state file in S3
    region         = "ap-south-1" # Your chosen region
    encrypt        = true # Encrypt the state file in S3
  }
}

provider "aws" {
  region = var.aws_region
}
