# Print jenkins ec2 public ip
output "jenkins-instance-public-ip"{
    value = module.jenkins.jenkins-instance-public-ip 
}