# terraform/ecs.tf
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# IAM role for ECS tasks to execute (Task Execution Role)
# Grants permissions for ECS agent to pull images from ECR, publish logs to CloudWatch
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM role for ECS tasks (Task Role)
# Grants permissions for the application running INSIDE the container (e.g., reading Secrets Manager)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the custom secrets read policy to the task role
resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_read_policy.arn
}

# Backend Task Definition (Fargate compatible)
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend-task"
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # For Docker operations and logs
  task_role_arn            = aws_iam_role.ecs_task_role.arn          # For application-specific permissions
  container_definitions    = jsonencode([
    {
      name  = "backend-app"
      image = var.backend_image # Image URI passed from CI/CD
      portMappings = [
        {
          containerPort = 5001 # Backend listens internally on 5001
          hostPort      = 5001 # For Fargate, hostPort must match containerPort if specified
        }
      ]
      environment = [ # Example environment variables
        {
          name  = "FLASK_APP"
          value = "app.py"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      # How to fetch secrets from Secrets Manager at runtime (example, uncomment if needed)
      # secrets = [
      #   {
      #     name = "MY_DB_PASSWORD"
      #     valueFrom = aws_secretsmanager_secret_version.example_secret_version.arn # Example secret
      #   }
      # ]
    }
  ])
  # Ensure this task definition is re-created if the image changes
  lifecycle {
    create_before_destroy = true
  }
}

# Frontend Task Definition (Fargate compatible)
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = jsonencode([
    {
      name  = "frontend-app"
      image = var.frontend_image # Image URI passed from CI/CD
      portMappings = [
        {
          containerPort = 3000 # Frontend listens internally on 3000 (Next.js default)
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "NEXT_PUBLIC_BACKEND_URL"
          # Frontend reaches backend via ALB DNS name and the specific path
          # The ALB will route /api/* and /health to the backend service.
          value = "http://${aws_lb.main.dns_name}/api" # Note: ALB listener rule paths
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  lifecycle {
    create_before_destroy = true
  }
}

# Backend ECS Service
# Manages running instances of the backend task definition
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn # References the backend task definition
  desired_count   = 2 # Run 2 instances for high availability and load balancing
  launch_type     = "FARGATE" # Use Fargate for serverless containers

  network_configuration {
    subnets         = aws_subnet.public.*.id # Deploy tasks into public subnets
    security_groups = [aws_security_group.ecs_tasks_sg.id] # Attach ECS task security group
    assign_public_ip = true # Tasks need public IP to pull images and communicate outbound
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn # Attach to backend ALB target group
    container_name   = "backend-app" # Name of the container in task definition
    container_port   = 5001 # Port on the container for the target group
  }

  # Force a new deployment when task definition or image changes
  force_new_deployment = true
  # Rollback alarms (optional, advanced)
  # deployment_controller {
  #   type = "ECS"
  # }

  tags = {
    Name = "${var.project_name}-backend-service"
  }
}

# Frontend ECS Service
# Manages running instances of the frontend task definition
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn # References the frontend task definition
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.public.*.id
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn # Attach to frontend ALB target group
    container_name   = "frontend-app"
    container_port   = 3000 # Port on the container for the target group
  }

  force_new_deployment = true

  tags = {
    Name = "${var.project_name}-frontend-service"
  }
}
