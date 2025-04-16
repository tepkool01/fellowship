resource "aws_cloudwatch_log_group" "this" {
  lifecycle {
    ignore_changes = all
  }
}