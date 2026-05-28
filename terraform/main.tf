provider "aws" {
    region = "ap-south-1"
}

provider "kubernetes" {
    host = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(
        data.aws_eks_cluster.eks.certificate_authority[0].data
    )
    token = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
    kubernetes{
        host = data.aws_eks_cluster.eks.endpoint
        cluster_ca_certificate = base64decode(
            data.aws_eks_cluster.eks.certificate_authority[0].data
        )
        token = data.aws_eks_cluster_auth.eks.token
    }
}   

data "aws_eks_cluster" "eks"{
    name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks"{
    name = var.cluster_name
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
