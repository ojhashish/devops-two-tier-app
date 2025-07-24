# terraform/alb.tf
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Internet-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # Attach ALB security group
  subnets            = aws_subnet.public.*.id # Deploy ALB in public subnets
  enable_deletion_protection = false # Set to true in production

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for Backend Service
# Routes traffic to ECS tasks listening on port 5001
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 5001 # Backend's container port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargate tasks register as IP targets

  health_check {
    path                = "/health" # Use backend's /health endpoint for health checks
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200" # Expect HTTP 200 OK
  }
  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# Target Group for Frontend Service
# Routes traffic to ECS tasks listening on port 3000
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-frontend-tg"
  port        = 3000 # Frontend's container port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/" # Use frontend's root path for health checks
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = {
    Name = "${var.project_name}-frontend-tg"
  }
}

# ALB Listener for HTTP on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action: return a 404 response if no rules match
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Page not found."
      status_code  = "404"
    }
  }
  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# ALB Listener Rule for Frontend traffic
# Routes all traffic to the frontend by default (catch-all)
resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100 # Lower priority means it's evaluated after higher priority rules

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    path_pattern {
      values = ["/*"] # Matches all paths
    }
  }
  tags = {
    Name = "${var.project_name}-frontend-rule"
  }
}

# ALB Listener Rule for Backend API traffic
# Routes specific API paths and health check to the backend service
resource "aws_lb_listener_rule" "backend_api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 90 # Higher priority than frontend rule, so evaluated first

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health"] # Matches requests starting with /api/ or /health
    }
  }
  tags = {
    Name = "${var.project_name}-backend-api-rule"
  }
}

# Output the ALB's DNS name for easy access
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}
