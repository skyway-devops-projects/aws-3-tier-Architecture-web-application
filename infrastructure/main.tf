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


resource "aws_instance" "bastion_host" {
  ami             = data.aws_ami.amzn_linux_2023_latest.id
  instance_type   = var.instance_type_bastion
  security_groups = [module.security.bastion_security_group_id]
  subnet_id       = element(module.vpc.public_subnet_ids, 0)
  key_name        = var.key_name
  tags            = merge(local.common_tags, { Name = "${local.name}-baston-host" })
}

resource "aws_instance" "mariadb" {
  ami             = "ami-0295aae70ff5e0fcc"
  instance_type   = var.instance_type
  security_groups = [module.security.db_security_group_id]
  subnet_id       = element(module.vpc.private_subnet_ids, 0)
  key_name        = var.key_name
  tags            = merge(local.common_tags, { Name = "${local.name}-ec2-mariadb" })
  user_data       = templatefile("${path.module}/scripts/mysql.sh", {})
}

resource "aws_instance" "memcached" {
  ami             = "ami-0295aae70ff5e0fcc"
  instance_type   = var.instance_type
  security_groups = [module.security.db_security_group_id]
  subnet_id       = element(module.vpc.private_subnet_ids, 0)
  key_name        = var.key_name
  tags            = merge(local.common_tags, { Name = "${local.name}-ec2-memcached" })
  user_data       = templatefile("${path.module}/scripts/memcache.sh", {})
}

resource "aws_instance" "rabbitmq" {
  ami             = "ami-013f478ef10960da1"
  instance_type   = var.instance_type
  security_groups = [module.security.db_security_group_id]
  subnet_id       = element(module.vpc.private_subnet_ids, 0)
  key_name        = var.key_name
  user_data       = templatefile("${path.module}/scripts/rabbitmq.sh", {})

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