output "jenkins-instance-public-ip"{
    value = aws_instance.jenkins-server.public_ip 
}

output "jenkins-instance-id" {
    value = aws_instance.jenkins-server.id
}