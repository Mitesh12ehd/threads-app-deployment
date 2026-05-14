# jenkins ec2
variable "jenkins_ssh_key" {}
variable "jenkins_availability_zone"{}
variable "jenkins_instance_type" {}

# ecr
variable "ecr_repo_name"{}

# eks
variable cluster_name{}

# for node group
variable node_group_instance_type {}
variable min_size{}
variable max_size{}
variable desired_size{}