output "log_group_arn" {
    value = aws_cloudwatch_log_group.dapp_ecs_service_log_group.arn
}