resource "aws_ecr_repository" "this" {
  name = var.repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}
