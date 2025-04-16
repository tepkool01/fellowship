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
  vpc_id                  = module.vpc.id
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
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.name_prefix}-cluster"
  cluster_version = "1.28"
  subnets         = aws_subnet.public[*].id
  vpc_id          = module.vpc.id

  node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.small"]
    }
  }
}