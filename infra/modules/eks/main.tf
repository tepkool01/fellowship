module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.name_prefix}-cluster"
  cluster_version = "1.28"
  subnet_ids      = aws_subnet.public[*].id
  vpc_id          = module.vpc.id

  eks_managed_node_groups = {
    default = {
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      instance_types  = ["t3.small"]
    }
  }
}
