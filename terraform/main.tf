provider "aws" {
    region = "ap-south-1"
}

module "jenkins"{
    source = "./modules/jenkins"
    jenkins_availability_zone = var.jenkins_availability_zone
    jenkins_instance_type = var.jenkins_instance_type
    jenkins_ssh_key = var.jenkins_ssh_key
}

module "ecr"{
    source = "./modules/ecr"
    ecr_repo_name = var.ecr_repo_name
}

module "eks" {
    source = "./modules/eks"
    cluster_name = var.cluster_name
    node_group_instance_type = var.node_group_instance_type
    min_size = var.min_size
    max_size = var.max_size
    desired_size = var.desired_size
}