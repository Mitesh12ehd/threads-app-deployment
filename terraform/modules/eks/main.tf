module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.8.1"

    name = "eks-vpc"
    cidr = "10.0.0.0/16"

    private_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    public_subnets = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
    azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true
    enable_dns_support   = true

    // tags to give information to kubernetes to use this subnet and resources
    tags = {
        "kubernetes.io/cluster/thread-app-eks-cluster" = "shared"
    }   
    public_subnet_tags = {
        "kubernetes.io/cluster/thread-app-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1
    }
    private_subnet_tags = {
        "kubernetes.io/cluster/thread-app-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}

module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "20.14.0"

    cluster_name = var.cluster_name
    cluster_version = "1.30"

    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets
    cluster_endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    cluster_addons = {
        coredns    = { most_recent = true }
        kube-proxy = { most_recent = true }
        vpc-cni    = { most_recent = true }
    }

    eks_managed_node_groups = {
        default = {
            name           = "eks-node-group"
            instance_types = [var.node_group_instance_type]
            ami_type       = "AL2_x86_64"
            capacity_type  = "ON_DEMAND"

            min_size     = var.min_size
            max_size     = var.max_size
            desired_size = var.desired_size

            use_latest_ami_release_version = true
            disk_size                      = 20

            update_config = {
                max_unavailable_percentage = 50
            }

            iam_role_additional_policies = {
                ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
            }

            labels = {
                Environment = "dev"
                NodeGroup   = "default"
            }

            tags = {
                Environment = "dev"
                ManagedBy   = "terraform"
            }
        }
    }


    tags = {
        Environment = "dev"
        ManagedBy   = "terraform"
    }
}

resource "aws_iam_policy" "alb_controller_policy" {
    name = "AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/iam_service_account_policy.json")
}

module "alb_controller_irsa_role"{
    source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
    version = "5.39.0"

    create_role = true
    role_name = "AmazonEKSLoadBalancerControllerRole"
    provider_url = replace(
        module.eks.cluster_oidc_issuer_url,
        "https://"  ,
        ""
    )

    role_policy_arns = [
        aws_iam_policy.alb_controller_policy.arn
    ]

    oidc_fully_qualified_subjects = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
    ]
}

resource "kubernetes_service_account" "alb_controller" {
    metadata {
        name = "aws-load-balancer-controller"
        namespace = "kube-system"
        annotations = {
            "eks.amazonaws.com/role-arn" = module.alb_controller_irsa_role.iam_role_arn
        }
    }

    depends_on = [module.eks]
}

resource "helm_release" "aws_load_balancer_controller" {
    name = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart = "aws-load-balancer-controller"
    namespace = "kube-system"
    depends_on = [ 
        kubernetes_service_account.alb_controller 
    ]
    set {
        name  = "clusterName"
        value = module.eks.cluster_name
    }

    set {
        name  = "serviceAccount.create"
        value = "false"
    }

    set {
        name  = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    }

    set {
        name  = "region"
        value = "ap-south-1"
    }

    set {
        name  = "vpcId"
        value = module.vpc.vpc_id
    }
}