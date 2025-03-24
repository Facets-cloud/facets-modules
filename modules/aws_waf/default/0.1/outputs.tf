locals {
  output_interfaces = {}
  output_attributes = {
    arn = aws_wafv2_web_acl.this.arn
  }
}
