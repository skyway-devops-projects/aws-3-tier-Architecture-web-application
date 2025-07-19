variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# variable "domain_name" {
#   description = "Domain Name"
#   type        = string
# }

variable "private_zone_id" {
  description = "Private Zone"
  type        = string
}

variable "internal_record_name" {
  description = "Internal Record Name"
  type        = string
}

variable "record" {
  description = "Records Ip"
  type        = list(string)
}