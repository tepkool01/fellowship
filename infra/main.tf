provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  name_prefix = var.name_prefix
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.name_prefix}-subnet-${count.index}"
  }
}

module "ecr" {
  source    = "./modules/ecr"
  repo_name = var.name_prefix
}


module "eks" {
  create_cloudwatch_log_group = false
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.31"
  cluster_name    = "${var.name_prefix}-cluster"
  cluster_version = "1.31"
  subnet_ids      = aws_subnet.public[*].id
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      instance_types  = ["t3.small"]
    }
  }
  cluster_encryption_config = [
  {
    provider_key_alias = "alias/eks/fellowship-cluster-alt"
    resources          = ["secrets"]
  }
]
}

resource "aws_cloudwatch_log_group" "eks" {
  depends_on = [module.eks]
  name              = "/aws/eks/${var.name_prefix}-cluster/cluster"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}
