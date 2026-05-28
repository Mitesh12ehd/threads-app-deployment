# Print jenkins ec2 public ip
output "jenkins-instance-public-ip"{
    value = module.jenkins.jenkins-instance-public-ip 
}

# Print ECR repository URI to tag image
output "ecr-repository-uri" {
    value = module.ecr.ecr-repository-uri
}