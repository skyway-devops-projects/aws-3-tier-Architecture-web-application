variable "iam_user_name" {}
variable "bucket_name" {}
variable "table_name" {}
variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}
