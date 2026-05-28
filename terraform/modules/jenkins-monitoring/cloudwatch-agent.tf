# To Store cloudwatch agent configuration json
# Run this json with cloudwatch agent on ec2

variable "jenkins_log_group" {}
variable "syslog_log_group" {}
variable "secure_log_group" {}
variable "docker_log_group" {}

locals {
    agent_config = jsonencode({
        agent = {
            metrics_collection_interval = 60
            run_as_user = "root"
        }

        metrics = {
            namespace = "CWAgent"
            append_dimension = {
                InstanceId = "$${{aws:InstanceId}}"
            }
            metrics_collected = {
                mem = {
                    measurement = ["mem_used_percent"]
                    metrics_collection_interval = 60
                }
                disk = {
                    resources = ["/", "/var"]
                    measurement = ["disk_used_percent", "disk_inodes_used_percent"]
                    metrics_collection_interval = 60
                    drop_device = true
                }
                swap = {
                    measurement = ["swap_used_percent"]
                    metrics_collection_interval = 60
                }
            }
        }

        logs = {
            logs_collected = {
                files = {
                    collect_list = [
                        # Jenkins container logs via Docker log file
                        {
                            file_path               = "/var/lib/docker/containers/*/*.log"
                            log_group_name          = var.jenkins_log_group
                            log_stream_name         = "jenkins-container-{instance_id}"
                            multi_line_start_pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
                            retention_in_days       = 30
                        },

                        # Docker daemon log (journald → file export or daemon log)
                        {
                            file_path         = "/var/log/docker"
                            log_group_name    = var.docker_log_group
                            log_stream_name   = "docker-daemon-{instance_id}"
                            retention_in_days = 14
                        },

                        # SSH authentication log — Amazon Linux: /var/log/secure; Ubuntu: /var/log/auth.log
                        {
                            file_path         = "/var/log/secure"
                            log_group_name    = var.secure_log_group
                            log_stream_name   = "ssh-auth-{instance_id}"
                            retention_in_days = 30
                        },

                        # Syslog — catches OOM killer events
                        {
                            file_path         = "/var/log/messages"
                            log_group_name    = var.syslog_log_group
                            log_stream_name   = "syslog-{instance_id}"
                            retention_in_days = 14
                        }
                    ]
                }
            }
        }
    })
}

resource "aws_ssm_parameter" "cw+agent_config" {
    name = "/AmazonCloudWatch-jenkins-agent-config"
    description = "CloudWatch Agent configuration for Jenkins monitoring on jenkins"
    type = "String"
    value = local.agent_config

    tags = {
        Name = "jenkins-cloudwatch-agent-config"
    }
}

output "ssm_parameter_name" { value = aws_ssm_parameter.cw_agent_config.name }
output "ssm_parameter_arn"  { value = aws_ssm_parameter.cw_agent_config.arn }