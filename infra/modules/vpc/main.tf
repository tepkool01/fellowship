resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes = all
  }
}