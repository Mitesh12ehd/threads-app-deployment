variable "ec2_instance_id" {}

variable "critical_sns_arn" {}
variable "warning_sns_arn" {}

variable "jenkins_log_group" {}
variable "syslog_log_group" {}
variable "secure_log_group" {}
variable "docker_log_group" {}

locals {
    custom_ns = "jenkins/OperationalMetrics"
    cwa_ns = "CWAgent"
}

#### Critical alarm ####
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
    alarm_name = "jenkins-critical-ec2-status-check-failed"
    alarm_description = "EC2 instance or system status check failed. Stop/Start instance to migrate to a healthy host."
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    metric_name = "StatusCheckFailed"
    namespace = "AWS/EC2"
    period = 60
    statistic = "Maximum"
    threshold = 1
    treat_missing_data = "breaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
    }

    alarm_actions = [var.critical_sns_arn]
    ok_actions = [var.critical_sns_arn]

    tags = {
        Name = "jenkins-critical-ec2-status-check"
        Severity = "critical"
    }
}

resource "aws_cloudwatch_metric_alarm" "container_not_running" {
    alarm_name = "jenkins-critical-jenkins-container-not-running"
    alarm_description = "Jenkins Docker container is not running. Run: docker start jenkins. Check: docker logs jenkins"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = 1
    metric_name = "JenkinsContainerRunning"
    namespace = local.custom_ns
    period = 60
    statistic = "Minimum"
    threshold = 1
    treat_missing_data = "breaching"

    alarm_actions = [var.critical_sns_arn]
    ok_actions = [var.critical_sns_arn]

    tags = {
        Name = "jenkins-critical-container-not-running"
        Severity = "critical"
    }
}

resource "aws_cloudwatch_metric_alarm" "jenkins_http_down" {
    alarm_name = "jenkins-critical-jenkins-http-down"
    alarm_description = "Jenkins HTTP health check failing for 3+ consecutive minutes. Run: docker restart jenkins. Check: docker logs jenkins --tail 100"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = 3
    metric_name = "JenkinsHealthy"
    namespace = local.custom_ns
    period = 60
    statistic = "Minimum"
    threshold = 1
    treat_missing_data = "breaching"

    alarm_actions = [var.critical_sns_arn]
    ok_actions = [var.critical_sns_arn]

    tags = {
        Name = "jenkins-critical-jenkins-http"
        Severity = "critical"
    }
}

resource "aws_cloudwatch_metric_alarm" "disk_critical" {
    alarm_name = "jenkins-critical-disk-usage-high"
    alarm_description = "Disk usage ≥90%. Run: docker system prune -f && sudo find /var/lib/jenkins/workspace -mtime +7 -delete"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "disk_used_percent"
    namespace = local.cwa_ns
    period = 60
    statistic = "Maximum"
    threshold = 90
    treat_missing_data = "breaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
        path = "/"
        fstype = "xfs"
    }

    alarm_actions = [var.critical_sns_arn]
    ok_actions  = [var.critical_sns_arn]

    tags = {
        Name = "jenkins-critical-disk"
        Severity = "critical"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory_critical" {
    alarm_name = "jenkins-critical-memory-usage-high"
    alarm_description = "Memory usage ≥90%. OOM kill imminent. Check: free -m; docker stats. Consider increasing instance type or reducing Jenkins heap."
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    metric_name = "mem_used_percent"
    namespace = local.cwa_ns
    period = 60
    statistic = "Maximum"
    threshold = 90
    treat_missing_data = "breaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
    }

    alarm_actions = [var.critical_sns_arn]
    ok_actions = [var.critical_sns_arn]

    tags = {
        Name = "jenkins-critical-memory"
        Severity  = "critical"
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu_warning" {
    alarm_name = "jenkins-warning-cpu-high"
    alarm_description = "CPU ≥85% for 15 minutes. Check: top -b -n1 | head -20. Identify runaway builds in Jenkins UI."
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 3
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 300
    statistic = "Average"
    threshold = 85
    treat_missing_data = "notBreaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
    }

    alarm_actions = [var.warning_sns_arn]
    ok_actions = [var.warning_sns_arn]

    tags = {
        Name = "jenkins-warning-cpu"
        Severity = "warning"
    }
}

##### Warning alarm #####
resource "aws_cloudwatch_metric_alarm" "memory_warning" {
    alarm_name = "jenkins-warning-memory-elevated"
    alarm_description = "Memory usage ≥75%. Monitor trend. If sustained, plan instance resize or reduce Jenkins executor count."
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 3
    metric_name = "mem_used_percent"
    namespace = local.cwa_ns
    period = 300
    statistic = "Average"
    threshold = 75
    treat_missing_data = "notBreaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
    }

    alarm_actions = [var.warning_sns_arn]
    ok_actions = [var.warning_sns_arn]

    tags = {
        Name = "jenkins-warning-memory"
        Severity = "warning"
    }
}

resource "aws_cloudwatch_metric_alarm" "disk_warning" {
    alarm_name = "jenkins-warning-disk-usage-elevated"
    alarm_description = "Disk usage ≥75%. Schedule cleanup: docker system prune -f. Review Jenkins build retention policy."
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "disk_used_percent"
    namespace = local.cwa_ns
    period = 300
    statistic = "Maximum"
    threshold = 75
    treat_missing_data = "notBreaching"

    dimensions = {
        InstanceId = var.ec2_instance_id
        path       = "/"
        fstype     = "xfs"
    }

    alarm_actions = [var.warning_sns_arn]
    ok_actions    = [var.warning_sns_arn]

    tags = {
        Name = "jenkins-warning-disk"
        Severity = "warning"
        ManagedBy = "terraform"
    }
}

resource "aws_cloudwatch_metric_alarm" "container_restarts" {
    alarm_name = "jenkins-warning-container-restart-rate"
    alarm_description = "Jenkins container has restarted ≥3 times in the evaluation window. Check: docker logs jenkins --tail 200. Disable auto-restart to debug: docker update --restart=no jenkins"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "JenkinsContainerRestartCount"
    namespace = local.custom_ns
    period = 3600
    statistic = "Maximum"
    threshold = 3
    treat_missing_data = "notBreaching"

    alarm_actions = [var.warning_sns_arn]
    ok_actions = [var.warning_sns_arn]

    tags = {
        Name = "jenkins-warning-container-restarts"
        Severity = "warning"
    }
}

resource "aws_cloudwatch_metric_alarm" "ssh_auth_failures" {
    alarm_name = "jenkins-warning-ssh-auth-failures"
    alarm_description = "≥10 SSH auth failures in 5 minutes — possible brute force. Check: grep 'Failed password' /var/log/secure | awk '{print $11}' | sort | uniq -c | sort -rn"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "SSHAuthFailureCount"
    namespace = local.custom_ns
    period = 300
    statistic = "Sum"
    threshold = 10
    treat_missing_data = "notBreaching"

    alarm_actions = [var.warning_sns_arn]
    ok_actions = [var.warning_sns_arn]

    tags = {
        Name = "jenkins-warning-ssh-failures"
        Severity = "warning"
    }
}
