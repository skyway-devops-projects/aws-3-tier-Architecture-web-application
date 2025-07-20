output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.web_alb.zone_id
}