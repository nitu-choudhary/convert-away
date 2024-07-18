resource "aws_ecs_cluster" "dapp_ecs_cluster" {
  name = var.dapp_ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_default_vpc" "default_vpc" {}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = var.availability_zones[0]
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = var.availability_zones[1]
}

resource "aws_ecs_task_definition" "dapp_ecs_task" {
  family                   = var.dapp_ecs_task_family
  container_definitions    = <<DEFINITION
    [
        {
          "name": "${var.dapp_ecs_task_name}",
          "image": "${var.ecr_repo_url}",
          "essential": true,
          "portMappings": [
              {
              "containerPort": ${var.container_port},
              "hostPort": ${var.container_port}
              }
          ],
          "memory": 512,
          "cpu": 256,
          "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
              "awslogs-group": "${var.dapp_ecs_service_log_group}",
              "awslogs-region": "us-east-1",
              "awslogs-stream-prefix": "ecs"
            }
          }
        }
    ]
    DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "dapp_alb" {
  name               = var.dapp_alb_name
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  security_groups = ["${aws_security_group.dapp_alb_sg.id}"]
}

resource "aws_security_group" "dapp_alb_sg" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "dapp_alb_target_group" {
  name        = var.dapp_alb_target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id
}

resource "aws_alb_listener" "dapp_alb_listener" {
  load_balancer_arn = aws_alb.dapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.dapp_alb_target_group.arn
  }
}

resource "aws_ecs_service" "dapp_ecs_service" {
  name            = var.dapp_ecs_service_name
  cluster         = aws_ecs_cluster.dapp_ecs_cluster.id
  task_definition = aws_ecs_task_definition.dapp_ecs_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.dapp_alb_target_group.arn
    container_name   = jsondecode(aws_ecs_task_definition.dapp_ecs_task.container_definitions)[0].name
    container_port   = var.container_port
  }

  network_configuration {
    subnets = [
      "${aws_default_subnet.default_subnet_a.id}",
      "${aws_default_subnet.default_subnet_b.id}"
    ]
    security_groups  = ["${aws_security_group.dapp_ecs_service_sg.id}"]
    assign_public_ip = true
  }
}

resource "aws_security_group" "dapp_ecs_service_sg" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.dapp_alb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs-alert_High-CPUReservation" {
  alarm_name          = "ecs-alert_High-CPUReservation"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period              = "60"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"

  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU Reservation on ECS"

  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = var.dapp_ecs_cluster_name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_log_group" "dapp_lg" {
  name              = var.dapp_ecs_service_log_group
  retention_in_days = var.retention_days
}