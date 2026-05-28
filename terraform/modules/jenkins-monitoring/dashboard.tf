variable "aws_region" {}           
variable "ec2_instance_id" {}

variable "jenkins_log_group" {}
variable "syslog_log_group" {}        
variable "secure_log_group" {} 
variable "docker_log_group"{}

variable "jenkins_error_metric_name"{}
variable "ssh_failure_metric_name"{}
variable "oom_event_metric_name"{}
variable "docker_error_metric_name"{}

variable "metric_namespace"{}

locals {
    custom_ns = var.metric_namespace
    cwa_ns = "CWAgent"
    ec2_ns = "AWS/EC2"
}

# Needed to build alarm ARNs for the alarm widget
data "aws_caller_identity" "current" {}

# Infrastructure dashboard
resource "aws_cloudwatch_dashboard" "infrastructure_health" {
    dashboard_name = "jenkins-infrastructure-health"
    dashboard_body = jsonencode({
        widgets = [

            # Row 1: CPU + Memory side by side
            {
                type = "metric"
                x = 0
                y = 0
                width = 12
                height = 6
                properties = {
                    title = "CPU Utilization (%)"
                    view = "timeSeries"
                    state = "Average"
                    period = "300"
                    metrics = [
                        [
                            local.ec2_ns,
                            "CPUUtilization",
                            "InstanceId",
                            var.ec2_instance_id
                        ]
                    ]
                    annotations = {
                        horizontal = [
                            { label = "Warning", value = 85, color = "#ff7f0e" },
                            { label = "Scale up", value = 95, color = "#d62728" }
                        ]
                    }
                    yAxis = { left = { min = 0, max = 100 } }
                    region = var.aws_region
                }
            },
            {
                type = "metric"
                x = 12
                y = 0
                width = 12
                height = 6
                properties = {
                    title  = "Memory Used (%)"
                    view   = "timeSeries"
                    stat   = "Average"
                    period = 300
                    metrics = [
                        [
                            local.cwa_ns,
                            "mem_used_percent", 
                            "InstanceId", 
                            var.ec2_instance_id
                        ]
                    ]
                    annotations = {
                        horizontal = [
                            { label = "Warning", value = 75, color = "#ff7f0e" },
                            { label = "Critical", value = 90, color = "#d62728" }
                        ]
                    }
                    yAxis = { left = { min = 0, max = 100 } }
                    region = var.aws_region
                }
            },

            # Row 2: Disk usage + Status Check alarm
            {
                type = "metric"
                x = 0
                y = 6
                width = 12
                height = 6
                properties = {
                    title  = "Disk Used — / (root volume) (%)"
                    view   = "timeSeries"
                    stat   = "Maximum"
                    period = 300
                    metrics = [
                        [
                            local.cwa_ns, 
                            "disk_used_percent", 
                            "InstanceId", 
                            var.ec2_instance_id, 
                            "path", "/", 
                            "fstype", "xfs"
                        ]
                    ]
                    annotations = {
                        horizontal = [
                            { label = "Warning", value = 75, color = "#ff7f0e" },
                            { label = "Critical", value = 90, color = "#d62728" }
                        ]
                    }
                    yAxis = { left = { min = 0, max = 100 } }
                    region = var.aws_region
                }
            },
            {
                type = "alarm"
                x = 12
                y = 6
                width = 12
                height = 6
                properties = {
                    title = "EC2 Status Checks"
                    alarms = [
                        "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:jenkins-critical-ec2-status-check-failed"
                    ]
                }
            },

            # Row 3: Network in/out (anomaly detection, no threshold)
            {
                type = "metric"
                x = 0
                y = 12
                width = 24
                height = 6
                properties = {
                    title = "Network Traffic (bytes/min)"
                    view = "timeSeries"
                    stat = "Sum"
                    period = 300
                    metrics = [
                        [local.ec2_ns, "NetworkIn",  "InstanceId", var.ec2_instance_id, { label = "Network In",  color = "#1f77b4" }],
                        [local.ec2_ns, "NetworkOut", "InstanceId", var.ec2_instance_id, { label = "Network Out", color = "#ff7f0e" }]
                    ]
                    region = var.aws_region
                }
            }
        ]
    })
}

# Jenkins Service dashboard
resource "aws_cloudwatch_dashboard" "jenkins_service" {
    dashboard_name = "jenkins-service"

    dashboard_body = jsonencode({
        widgets = [
            # Row 1: Jenkins healthy + container running
            {
                type = "metric"
                x = 0
                y = 0
                width = 8
                height = 6
                properties = {
                    title  = "Jenkins HTTP Health (1=Up, 0=Down)"
                    view   = "timeSeries"
                    stat   = "Minimum"
                    period = 60
                    metrics = [[local.custom_ns, "JenkinsHealthy"]]
                    annotations = {
                        horizontal = [{ label = "Down", value = 0.5, color = "#d62728" }]
                    }
                    yAxis = { left = { min = 0, max = 1 } }
                    region = var.aws_region
                }
            },
            {
                type = "metric"
                x = 8
                y = 0
                width = 8
                height = 6
                properties = {
                    title  = "Container Running (1=Up, 0=Down)"
                    view   = "timeSeries"
                    stat   = "Minimum"
                    period = 60
                    metrics = [[local.custom_ns, "JenkinsContainerRunning"]]
                    annotations = {
                        horizontal = [{ label = "Down", value = 0.5, color = "#d62728" }]
                    }
                    yAxis = { left = { min = 0, max = 1 } }
                    region = var.aws_region
                }
            },
            {
                type = "metric"
                x = 16
                y = 0
                width = 8
                height = 6
                properties = {
                    title  = "Container Restarts (count/hr)"
                    view   = "timeSeries"
                    stat   = "Maximum"
                    period = 3600
                    metrics = [[local.custom_ns, "JenkinsContainerRestartCount"]]
                    annotations = {
                        horizontal = [{ label = "Warning threshold", value = 3, color = "#ff7f0e" }]
                    }
                    region = var.aws_region
                }
            },

            # Row 2: Container CPU + Memory
            {
                type = "metric"
                x = 0
                y = 6
                width = 12
                height = 6
                properties = {
                    title  = "Container CPU Usage (%)"
                    view   = "timeSeries"
                    stat   = "Average"
                    period = 300
                    metrics = [[local.cwa_ns, "container_cpu_usage_total", "ContainerName", "jenkins"]]
                    region = var.aws_region
                }
            },
            {
                type   = "metric"
                x = 12
                y = 6
                width = 12
                height = 6
                properties = {
                    title  = "Container Memory Usage (%)"
                    view   = "timeSeries"
                    stat   = "Average"
                    period = 300
                    metrics = [[local.cwa_ns, "container_memory_working_set", "ContainerName", "jenkins"]]
                    region = var.aws_region
                }
            },

            # Row 3: Active alarms for Jenkins
            {
                type   = "alarm"
                x = 0
                y = 12
                width = 24
                height = 6
                properties = {
                    title = "Jenkins Service Alarms"
                    alarms = [
                        "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:jenkins-critical-jenkins-container-not-running",
                        "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:jenkins-critical-jenkins-http-down",
                        "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:jenkins-warning-container-restart-rate"
                    ]
                }
            }
        ]
    })
}

# Logs & Failures dashboard
resource "aws_cloudwatch_dashboard" "logs_failures" {
    dashboard_name = "jenkins-logs-failures"

    dashboard_body = jsonencode({
        widgets = [

            # Row 1: Jenkins errors + Docker daemon errors
            {
                type   = "metric"
                x = 0
                y = 0
                width = 12
                height = 6
                properties = {
                    title  = "Jenkins ERROR count (per 5 min)"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [[local.custom_ns, var.jenkins_error_metric_name]]
                    region = var.aws_region
                }
            },
            {
                type   = "metric"
                x  = 12
                y = 0
                width = 12
                height = 6
                properties = {
                    title  = "Docker Daemon Errors (per 5 min)"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [[local.custom_ns, var.docker_error_metric_name]]
                    region = var.aws_region
                }
            },

            # Row 2: SSH failures + OOM events
            {
                type   = "metric"
                x = 0
                y = 6
                width = 12
                height = 6
                properties = {
                    title  = "SSH Auth Failures (per 5 min)"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [[local.custom_ns, var.ssh_failure_metric_name]]
                    annotations = {
                        horizontal = [{ label = "Warning threshold", value = 10, color = "#ff7f0e" }]
                    }
                    region = var.aws_region
                }
            },
            {
                type   = "metric"
                x = 12
                y = 6
                width = 12
                height = 6
                properties = {
                    title  = "OOM Killer Events"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [[local.custom_ns, var.oom_event_metric_name]]
                    annotations = {
                        horizontal = [{ label = "Any OOM = investigate", value = 1, color = "#d62728" }]
                    }
                    region = var.aws_region
                }
            },
            
            # Row 3: Log Insights widget — recent Jenkins errors
            {
                type   = "log"
                x = 0
                y = 12
                width = 24
                height = 9
                properties = {
                    title   = "Recent Jenkins ERROR lines (last 1 hour)"
                    view    = "table"
                    region  = var.aws_region
                    query   = "SOURCE '${var.jenkins_log_group}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50"
                    period  = 3600
                }
            }
        ]
    })
}