data "aws_eks_cluster_auth" "eks" {
    name = module.eks.cluster_name
}

output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
    value = module.eks.cluster_certificate_authority_data
}

output "cluster_token" {
    value     = data.aws_eks_cluster_auth.eks.token
    sensitive = true
}