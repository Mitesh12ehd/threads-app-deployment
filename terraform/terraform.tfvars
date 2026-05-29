# for jenkins
jenkins_availability_zone = "ap-south-1b"
jenkins_instance_type = "t3.small"
jenkins_ssh_key = "/home/mitesh/.ssh/id_rsa.pub"

# ecr
ecr_repo_name = "thread-app"

# eks
cluster_name = "thread-app-eks-cluster"
node_group_instance_type = "t3.small"
min_size = 1
max_size = 2
desired_size = 1