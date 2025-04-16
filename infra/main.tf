provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  name_prefix = var.name_prefix
}

module "ecr" {
  source    = "./modules/ecr"
  repo_name = var.name_prefix
}
