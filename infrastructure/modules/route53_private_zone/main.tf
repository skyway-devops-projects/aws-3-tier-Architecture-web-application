locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = "${var.environment}"
    CreatedBy   = "Terraform"
  }
}


resource "aws_route53_record" "internal_record" {
  zone_id = var.private_zone_id
  name    = var.internal_record_name
  type    = "A"
  ttl     = 300
  records = var.record
}