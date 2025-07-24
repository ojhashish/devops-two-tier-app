# terraform/versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Specify a compatible AWS provider version
    }
  }
  required_version = ">= 1.0.0" # Specify a compatible Terraform version
}

provider "aws" {
  region = var.aws_region # AWS region will be set by a variable
}
