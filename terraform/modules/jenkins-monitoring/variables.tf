locals {
    # general
    custom_ns = "jenkins/OperationalMetrics"
    cwa_ns = "CWAgent"
    ec2_ns = "AWS/EC2"

    # cloudwatch-agent
    jenkins_log_group = aws_cloudwatch_log_group.jenkins.name
    docker_log_group = aws_cloudwatch_log_group.docker.name 
    secure_log_group = aws_cloudwatch_log_group.secure.name 
    syslog_log_group = aws_cloudwatch_log_group.syslog.name 

    # dashboard
    jenkins_error_metric_name = aws_cloudwatch_log_metric_filter.jenkins_errors.metric_transformation[0].name
    ssh_failure_metric_name = aws_cloudwatch_log_metric_filter.ssh_failures.metric_transformation[0].name
    oom_event_metric_name = aws_cloudwatch_log_metric_filter.oom_events.metric_transformation[0].name
    docker_error_metric_name = aws_cloudwatch_log_metric_filter.docker_errors.metric_transformation[0].name

    # alarm
    critical_sns_arn = aws_sns_topic.critical.arn
    warning_sns_arn = aws_sns_topic.warning.arn
}

# alarm
variable "ec2_instance_id" {}

# dashboard
variable "aws_region" {}           

# sns
variable "alert_email"{}