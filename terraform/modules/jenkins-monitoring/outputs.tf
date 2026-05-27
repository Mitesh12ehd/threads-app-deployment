# sns
output "critical_topic_arn" { value = aws_sns_topic.critical.arn }
output "warning_topic_arn"  { value = aws_sns_topic.warning.arn }

# cloudwatch-agent.tf 
output "ssm_parameter_name" { value = aws_ssm_parameter.cw_agent_config.name }
output "ssm_parameter_arn"  { value = aws_ssm_parameter.cw_agent_config.arn }