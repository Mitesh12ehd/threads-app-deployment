# Print jenkins ec2 public ip
output "jenkins-instance-public-ip"{
    value = module.jenkins.jenkins-instance-public-ip 
}

# Print ECR repository URI to tag image
output "ecr-repository-uri" {
    value = module.ecr.ecr-repository-uri
}

# sns
output "critical_topic_arn" { value = module.jenkins-monitoring.critical_topic_arn }
output "warning_topic_arn"  { value = module.jenkins-monitoring.warning_topic_arn }