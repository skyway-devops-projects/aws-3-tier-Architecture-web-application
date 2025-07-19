terraform {
  required_version = "~> 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4"
    }
  }
  #   backend "s3" {
  #   bucket                = "vprofile_terraform_state_backend"
  #   key                   = "vprofile/terraform.tfstate"
  #   region                = "us-east-1"
  #   dynamodb_table        = "vprofile_terraform_state_locks"
  # }
}