variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "security_group_id" {
  type        = string
  description = "Load Balancer Securitygroup Id"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Load Balancer Public subnet ids"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

# variable "alb_listeners" {
#   default = {
#     http  = { port = 80,  protocol = "HTTP"  }
#     https = { port = 443, protocol = "HTTPS" }
#   }
# }

# variable "app_instace_id" {
#   type        = string
#   description = "Instace Id app"
# }

variable "certificate_arn" {
  type = string
  description = "Certificate arn"
}