# terraform/cloudwatch.tf
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 7 # Retain logs for 7 days
  tags = {
    Name = "${var.project_name}-backend-log-group"
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 7 # Retain logs for 7 days
  tags = {
    Name = "${var.project_name}-frontend-log-group"
  }
}
