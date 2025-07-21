locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = "${var.environment}"
    CreatedBy   = "Terraform"
  }
}

resource "aws_launch_template" "web_lt" {
  name = "${local.name}-web-lt"
  image_id = var.image_id
  vpc_security_group_ids = [ var.security_group_id_web]
  instance_type = var.instance_type
  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }
  user_data = var.user_data
   tags = merge(local.common_tags, { Name = "${local.name}-web-lt" })
}

resource "aws_autoscaling_group" "weg_ag" {
  name = "${local.name}-web-ag"
  launch_template {
id = aws_launch_template.web_lt.id
version = aws_launch_template.web_lt.latest_version
  }
  vpc_zone_identifier = var.web_subnet_ids
  min_size = 2
  desired_capacity = 1
  max_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  target_group_arns = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "Web-ASG"
    propagate_at_launch = true
  }
}
