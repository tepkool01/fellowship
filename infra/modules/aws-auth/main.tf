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

  aws_auth_roles = [
    for role_arn in var.eks_node_role_arns : {
      rolearn  = role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]
}
