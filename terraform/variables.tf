# terraform/variables.tf
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1" # Your chosen region, matches GitHub secret
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "two-tier-app"
}

variable "backend_image" {
  description = "Docker image tag for the backend service (e.g., ECR_URI:tag)"
  type        = string
}

variable "frontend_image" {
  description = "Docker image tag for the frontend service (e.g., ECR_URI:tag)"
  type        = string
}
