provider "aws" {
  region = var.aws_region
}
terraform {
  backend "s3" {
    bucket         = "my-fellowship-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "fellowship-terraform-locks"
    encrypt        = true
  }
}

data "aws_availability_zones" "available" {}

locals {
  cluster_encryption_config = {
    resources = ["secrets"]
    provider = {
      key_arn = aws_kms_key.eks.arn
    }
  }
}

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

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks/fellowship-cluster-final"
  target_key_id = aws_kms_key.eks.key_id

  lifecycle {
    ignore_changes = all
  }
}

module "eks" {
  create_cloudwatch_log_group = false
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.31"
  cluster_name    = "${var.name_prefix}-cluster"
  cluster_version = "1.32"
  subnet_ids      = aws_subnet.public[*].id
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      instance_types  = ["t3.small"]
      ami_type        = "AL2_x86_64"
    }
  }

  cluster_encryption_config = local.cluster_encryption_config
}

module "eks_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.31"

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::878527066650:root"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

#   aws_auth_roles = [
#     for role_arn in module.eks.eks_managed_node_group_iam_role_arns : {
#       rolearn  = role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = ["system:bootstrappers", "system:nodes"]
#     }
#   ]
}

resource "aws_cloudwatch_log_group" "eks" {
  depends_on        = [module.eks]
  name              = "/aws/eks/${var.name_prefix}-cluster/cluster"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# output "eks_node_role_arns" {
#   value = module.eks.eks_managed_node_group_iam_role_arns
# }