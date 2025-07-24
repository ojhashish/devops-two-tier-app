# terraform/vpc.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create two public subnets for high availability
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Dynamically create CIDR blocks within the VPC CIDR
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  # Map to different availability zones
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Public IP for resources in these subnets
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index}"
  }
}

# Internet Gateway for VPC to allow internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # Default route to the internet
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for Application Load Balancer (ALB)
# Allows HTTP and HTTPS traffic from anywhere on the internet
resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS access to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from all IPs
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from all IPs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group for ECS Tasks
# Allows all traffic from the ALB's security group (ensuring only ALB can reach tasks)
resource "aws_security_group" "ecs_tasks_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"

  ingress {
    from_port       = 0 # All ports
    to_port         = 0
    protocol        = "-1" # All protocols
    security_groups = [aws_security_group.alb_sg.id] # Allow only from ALB SG
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

# Data source to get available availability zones in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}
