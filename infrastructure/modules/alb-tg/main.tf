locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = "${var.environment}"
    CreatedBy   = "Terraform"
  }
}

resource "aws_lb" "web_alb" {
  name   = "${local.name}-web-alb"
  internal = false
  load_balancer_type = "application"
  ip_address_type = "ipv4"
  enable_deletion_protection = false
  security_groups = [ var.security_group_id ]
  subnets = var.public_subnet_ids
  tags = merge(local.common_tags, { Name = "${local.name}-web-alb" })
}

resource "aws_lb_target_group" "web_tg" {
  name  = "${local.name}-web-tg"
  target_type = "instance"
  protocol = "HTTP"
  port = 8080
  vpc_id = var.vpc_id
  health_check {
    enabled = true
    interval = 10
    timeout = 5
    path = "/"
    port = 8080
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ aws_lb.web_alb ]
}

resource "aws_lb_listener" "web-alb-listener" {
  for_each = var.alb_listeners
  load_balancer_arn = aws_lb.web_alb.arn
  port = each.value.port
  protocol = each.value.protocol
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
  depends_on = [ aws_lb.web_alb ]
}

resource "aws_lb_target_group_attachment" "web_tg_instace_attachement" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id = var.app_instace_id
  port = 8080
}