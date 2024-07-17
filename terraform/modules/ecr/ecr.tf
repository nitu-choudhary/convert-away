resource "aws_ecr_repository" "dapp_ecr_repo" {
  name = var.ecr_repo_name
}