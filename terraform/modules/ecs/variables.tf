variable "dapp_ecs_cluster_name" {
  description = "ECS cluster for dapp frontend"
  type        = string
}

variable "availability_zones" {
  description = "us-east-1 AZs"
  type        = list(string)
}

variable "dapp_ecs_task_family" {
  description = "ECS task family for dapp frontend"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "dapp_ecs_task_name" {
  description = "ECS task name for dapp frontend"
  type        = string
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  type        = string
}

variable "dapp_alb_name" {
  description = "ALB name"
  type        = string
}

variable "dapp_alb_target_group_name" {
  description = "ALB Target group name"
  type        = string
}

variable "dapp_ecs_service_name" {
  description = "ECS service name"
  type        = string
}