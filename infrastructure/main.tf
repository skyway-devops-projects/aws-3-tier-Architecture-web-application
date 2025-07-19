locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = "${var.environment}"
    CreatedBy   = "Terraform"
  }
}


# module "backend" {
#   source = "./modules/remote_backend"
#   environment = var.environment
#   project_name = var.project_name
#   iam_user_name = var.iam_user_name
#   bucket_name = var.bucket_name
#   table_name = var.table_name
# }

module "vpc" {
  source          = "./modules/vpc"
  environment     = var.environment
  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  azs             = var.availability_zones
}

module "security" {
  source       = "./modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}




resource "aws_instance" "mariadb" {
  ami                    = "ami-0295aae70ff5e0fcc"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.security.db_security_group_id]
  subnet_id              = element(module.vpc.private_subnet_ids, 0)
  key_name               = var.key_name
  tags                   = merge(local.common_tags, { Name = "${local.name}-ec2-mariadb" })
  user_data              = templatefile("${path.module}/scripts/mysql.sh", {})
}

resource "aws_instance" "memcached" {
  ami                    = "ami-0295aae70ff5e0fcc"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.security.db_security_group_id]
  subnet_id              = element(module.vpc.private_subnet_ids, 0)
  key_name               = var.key_name
  tags                   = merge(local.common_tags, { Name = "${local.name}-ec2-memcached" })
  user_data              = templatefile("${path.module}/scripts/memcache.sh", {})
}

resource "aws_instance" "rabbitmq" {
  ami                    = "ami-013f478ef10960da1"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.security.db_security_group_id]
  subnet_id              = element(module.vpc.private_subnet_ids, 0)
  key_name               = var.key_name
  user_data              = templatefile("${path.module}/scripts/rabbitmq.sh", {})

  tags = merge(local.common_tags, { Name = "${local.name}-ec2-rabbitmq" })
}

resource "aws_route53_zone" "private_zone" {
  name = var.domain_name
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  comment = "Private hosted zone for ${var.domain_name} backend servers"
  tags    = merge(local.common_tags, { Name = "${local.name}-${var.domain_name}" })
}


module "private_hosted_zone_backend_db_01" {
  source               = "./modules/route53_private_zone"
  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  private_zone_id      = aws_route53_zone.private_zone.id
  internal_record_name = "${var.internal_record_name_db_01}.${var.domain_name}"
  record               = [aws_instance.mariadb.private_ip]
  depends_on           = [aws_instance.mariadb]
}

module "private_hosted_zone_backend_mc_01" {
  source               = "./modules/route53_private_zone"
  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  private_zone_id      = aws_route53_zone.private_zone.id
  internal_record_name = "${var.internal_record_name_mc_01}.${var.domain_name}"
  record               = [aws_instance.memcached.private_ip]
  depends_on           = [aws_instance.memcached]
}

module "private_hosted_zone_backend_rmq_01" {
  source               = "./modules/route53_private_zone"
  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  private_zone_id      = aws_route53_zone.private_zone.id
  internal_record_name = "${var.internal_record_name_rmq_01}.${var.domain_name}"
  record               = [aws_instance.rabbitmq.private_ip]
  depends_on           = [aws_instance.rabbitmq]
}

resource "random_id" "bucket_suffix" {
  byte_length = 4  # Generates 8 hex chars
}

resource "aws_s3_bucket" "bucket_artifact_storage" {
  bucket = "${var.bucket_artifact_storage}-${random_id.bucket_suffix.hex}"  # Unique name
    tags = merge(local.common_tags, { Name = "${local.name}-${var.bucket_artifact_storage}" })
}

resource "aws_iam_role" "ec2_s3_role" {
  name = "${local.name}-s3-role"
  assume_role_policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }

    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "${local.name}-s3-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]

  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.name}-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}


resource "null_resource" "build_and_detect" {
  # provisioner "local-exec" {
  #   command = "mvn clean package"
  # }

  provisioner "local-exec" {
    command = <<EOT
    ../target/
    ls
    EOT
  }
}

resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.amzn_linux_2023_latest.id
  instance_type          = var.instance_type_bastion
  vpc_security_group_ids = [module.security.bastion_security_group_id]
  subnet_id              = element(module.vpc.public_subnet_ids, 0)
  key_name               = var.key_name
   iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  tags                   = merge(local.common_tags, { Name = "${local.name}-baston-host" })

      connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("${path.module}/private_key/vprofile-dev.pem")
      host = self.public_ip
    }

  provisioner "file" {
    source = "${path.module}/private_key/vprofile-dev.pem"
    destination = "/home/ec2-user/vprofile-dev.pem"
  }

    provisioner "file" {
    source = "../target/vprofile-v2.war"
    destination = "/home/ec2-user/vprofile-v2.war"
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("${path.module}/private_key/vprofile-dev.pem")
      host = self.public_ip
    }
  }
}


resource "aws_instance" "vprofile_app" {
  ami                    = "ami-013f478ef10960da1"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.security.app_security_group_id]
  subnet_id              = element(module.vpc.private_subnet_ids, 1)
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  user_data              = templatefile("${path.module}/scripts/tomcat_ubuntu.sh", {})
  tags                   = merge(local.common_tags, { Name = "${local.name}-ec2-vprofile-app" })
}


