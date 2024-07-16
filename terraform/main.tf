# AWS Provider
provider "aws" {
  region = "us-east-1"
}

#  Data Sources for Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "dapp_sg" {
  name        = "dapp_security_group"
  description = "Allow HTTP traffic"
  vpc_id      = data.aws_vpc.default.id # get default VPC id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from anywhere (for testing purposes, restrict in production)
  }
}

# IAM Role for ECS Task Execution (EC2)
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRolePolicy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# EC2 Instance for ECS
resource "aws_instance" "ecs_instance" {
  ami           = "ami-052efd3df9dad4825"  # Amazon Linux 2 AMI (replace with a suitable AMI for your region)
  instance_type = "t2.micro" 
  subnet_id     = data.aws_subnets.default.ids[0] 
  security_groups = [aws_security_group.dapp_sg.id]

  tags = {
    Name = "ecs-instance"
  }

  # Install and configure the Amazon ECS Container Agent
  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=$(aws ssm get-parameter --name dapp-cluster-name --query 'Parameter.Value' --output text) >> /etc/ecs/ecs.config
    yum install -y aws-cfn-bootstrap
  EOF
}

# SSM Parameter for ECS Cluster Name
resource "aws_ssm_parameter" "ecs_cluster_name" {
name  = "dapp-cluster-name"
type  = "String"
value = aws_ecs_cluster.dapp_cluster.name
}

# ECS Cluster
resource "aws_ecs_cluster" "dapp_cluster" {
  name = "dapp-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "frontend_task" {
    family                = "frontend-task"
    network_mode          = "awsvpc"   #For EC2
    requires_compatibilities = ["EC2"]
    cpu                   = 256
    memory                = 512  # Adjust based on your app's needs
    execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
    container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "choudharynitu/convertaway-react:latest"  
      essential = true
      portMappings = [
        {
          containerPort = 80 
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.dapp_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1    # Number of instances of your frontend to run
  launch_type     = "EC2"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.dapp_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_instance.ecs_instance] # Ensure the EC2 instance is created first
}

# Load Balancer & Target Group (Optional)
resource "aws_lb" "alb" {
    name                = "dapp-load-balancer"
    internal            = false
    load_balancer_type  = "application"
    subnets             = data.aws_subnets.default.ids
    security_groups     = [aws_security_group.dapp_sg.id]
}

resource "aws_lb_target_group" "tg" {
    name        = "dapp-target-group"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = data.aws_vpc.default.id
    target_type = "ip"
    health_check {
        path = "/"
    }
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# CloudWatch Log Group (for ECS logs)
resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/ecs/dapp-frontend"
  retention_in_days = 7
}