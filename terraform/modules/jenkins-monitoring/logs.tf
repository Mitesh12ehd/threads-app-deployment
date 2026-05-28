locals {
    metric_namespace = "jenkins/OperationalMetrics"
}

resource "aws_cloudwatch_log_group" "jenkins" {
    name = "/jenkins/logs"
    retention_in_days = 30

    tags = {
        Name = "jenkins-application-logs"
    }
}

resource "aws_cloudwatch_log_group" "docker" {
    name = "/system/docker"
    retention_in_days = 14

    tags = {
        Name = "docker-daemon-logs"
    }
}

resource "aws_cloudwatch_log_group" "secure" {
    name = "/system/secure"
    retention_in_days = 30

    tags = {
        Name = "ssh-auth-logs"
    }
}

resource "aws_cloudwatch_log_group" "syslog" {
    name = "/system/syslog"
    retention_in_days = 14

    tags = {
        Name = "system-syslog"
    }
}

# Metric Filter — Jenkins ERROR rate
# Matches lines containing ERROR from Jenkins stdout
resource "aws_cloudwatch_log_metric_filter" "jenkins_errors" {
    name = "jenkins-error-rate"
    log_group_name = aws_cloudwatch_log_group.jenkins.name
    pattern        = "[timestamp, level=ERROR, ...]"

    metric_transformation {
        name = "JenkinsErrorCount"
        namespace = local.metric_namespace
        value = "1"
        default_value = "0"
        unit = "Count"
    }
}

# Metric Filter — SSH authentication failures
# Matches sshd "Failed password" and "Invalid user" lines
resource "aws_cloudwatch_log_metric_filter" "ssh_failures" {
    name = "jenkins-ssh-auth-failures"
    log_group_name = aws_cloudwatch_log_group.secure.name
    pattern = "\"Failed password\" || \"Invalid user\" || \"authentication failure\""

    metric_transformation {
        name = "SSHAuthFailureCount"
        namespace = local.metric_namespace
        value = "1"
        default_value = "0"
        unit = "Count"
    }
}

# Metric Filter — OOM killer events
# Matches kernel "Out of memory: Kill process" from syslog
resource "aws_cloudwatch_log_metric_filter" "oom_events" {
    name = "jenkins-oom-killer-events"
    log_group_name = aws_cloudwatch_log_group.syslog.name
    pattern = "\"Out of memory\" || \"OOM killer\" || \"oom_kill_process\""

    metric_transformation {
        name = "OOMKillerEventCount"
        namespace = local.metric_namespace
        value = "1"
        default_value = "0"
        unit  = "Count"
    }
}

# Metric Filter — Docker daemon errors
# Matches "Error response from daemon" in Docker logs
resource "aws_cloudwatch_log_metric_filter" "docker_errors" {
    name = "jenkins-docker-daemon-errors"
    log_group_name = aws_cloudwatch_log_group.docker.name
    pattern = "\"Error response from daemon\" || \"level=error\" || \"level=fatal\""

    metric_transformation {
        name = "DockerDaemonErrorCount"
        namespace = local.metric_namespace
        value = "1"
        default_value = "0"
        unit = "Count"
    }
}

output "jenkins_log_group_name" { value = aws_cloudwatch_log_group.jenkins.name }
output "docker_log_group_name" { value = aws_cloudwatch_log_group.docker.name }
output "secure_log_group_name" { value = aws_cloudwatch_log_group.secure.name }
output "syslog_log_group_name" { value = aws_cloudwatch_log_group.syslog.name }

output "metric_namespace" { value = local.metric_namespace}
output "jenkins_error_metric_name" { value = aws_cloudwatch_log_metric_filter.jenkins_errors.metric_transformation[0].name }
output "ssh_failure_metric_name" { value = aws_cloudwatch_log_metric_filter.ssh_failures.metric_transformation[0].name }
output "oom_event_metric_name" { value = aws_cloudwatch_log_metric_filter.oom_events.metric_transformation[0].name }
output "docker_error_metric_name"  { value = aws_cloudwatch_log_metric_filter.docker_errors.metric_transformation[0].name }