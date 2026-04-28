provider "aws" {}

module "jenkins"{
    source = "./modules/jenkins"
    jenkins_availability_zone = var.jenkins_availability_zone
    jenkins_instance_type = var.jenkins_instance_type
    jenkins_ssh_key = var.jenkins_ssh_key
}

module "ecr"{
    source = "./modules/ecr"
}

module "eks" {
    source = "./modules/eks"
}