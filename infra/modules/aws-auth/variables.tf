variable "aws_auth_users" {
  description = "List of IAM users to add to the aws-auth configmap"
  type        = list(map(string))
  default     = []
}

variable "aws_auth_roles" {
  description = "List of IAM roles to add to the aws-auth configmap"
  type        = list(map(string))
  default     = []
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth configmap"
  type        = bool
  default     = true
}

variable "eks_node_role_arns" {
  description = "List of IAM role ARNs used by the EKS managed node group"
  type        = list(string)
}
