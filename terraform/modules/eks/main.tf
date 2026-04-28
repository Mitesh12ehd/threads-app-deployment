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

    cluster_name = "thread-app-eks-cluster"
    cluster_version = "1.29"

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
            instance_types = ["t3.small"]
            ami_type       = "AL2_x86_64"
            capacity_type  = "ON_DEMAND"

            min_size     = 1
            max_size     = 2
            desired_size = 1

            use_latest_ami_release_version = true
            disk_size                      = 20

            update_config = {
                max_unavailable_percentage = 50
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