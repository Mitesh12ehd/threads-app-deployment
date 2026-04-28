module "eks-vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "6.6.1"

    name = "eks-vpc"
    cidr = "10.0.0.0/16"

    private_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    public_subnets = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
    azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

    enable_nat_gateway = true
    single_nat_gateway = true


    // to get dns names attached to ip that we need to access it from browser
    enable_dns_hostnames = true

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
    version = "21.19.0"

    name = "thread-app-eks-cluster"
    kubernetes_version = "1.34"

    endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    // subnet where we want worker nodes 
    // we want all workload in private subnet for security reason
    subnet_ids = module.eks-vpc.private_subnets

    vpc_id = module.eks-vpc.vpc_id

    eks_managed_node_groups = {
        dev = {
            instance_types = ["c7i-flex.large"]
            min_size     = 1
            max_size     = 1
            desired_size = 1
        }
    }

    tags = {
        environment = "development"
        app = "thread-app"
    }
}