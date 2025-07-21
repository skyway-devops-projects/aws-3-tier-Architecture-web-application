variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}



variable "image_id" {
  type        = string
  description = "ami image id"
}

variable "security_group_id_web" {
  type        = string
  description = "securit group id"
}

variable "instance_type" {
  type        = string
  description = "instance type"
}

variable "iam_instance_profile_arn" {
  type = string
  description = "instance profile arn"
}

# variable "bucket_name" {
#   type = string
#   description = "bucket name"
# }

variable "web_subnet_ids" {
  type = list(string)
  description = "private web subnet ids"
}

variable "target_group_arn" {
  type = string
  description = "Targetgroup arn"
}

variable "user_data" {
    type = string
  description = "userdata"
}