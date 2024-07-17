terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

module "ecrRepo" {
  source        = "./modules/ecr"
  ecr_repo_name = "dapp-ecr-repo"
}

module "ecsCluster" {
  source = "./modules/ecs"

  dapp_ecs_cluster_name = "dapp-ecs-cluster"
  availability_zones    = ["us-east-1a", "us-east-1b"]

  dapp_ecs_task_family         = "dapp-ecs-task-family"
  ecr_repo_url                 = module.ecrRepo.repository_url
  container_port               = 80
  dapp_ecs_task_name           = "dapp-ecs-task"
  ecs_task_execution_role_name = "dapp-ecs-task-execution-role"

  dapp_alb_name              = "dapp-alb"
  dapp_alb_target_group_name = "dapp-alb-target-group"
  dapp_ecs_service_name      = "dapp-ecs-service"
}