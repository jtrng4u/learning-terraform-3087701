data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "blog_vpc"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1", "us-west-2"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  tags = {
    Name = "blog_vpc"
    Terraform = "true"
  }
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  target_groups = {
    ex-instance = {
      name_prefix      = "blog"
      protocol = "HTTP"
      port     = 80
      target_type      = "instance"
      target_id = aws_instance.blog.id
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = {
    Terraform = "true"
  }
}

module "blog_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "blog-asg"

  min_size                  = 1
  max_size                  = 2
  health_check_type         = "ELB"
  vpc_zone_identifier       = module.blog_vpc.public_subnets
  target_group_arns         = module.blog_alb.target_group_arns

  tags = {
    Terraform = "true"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [module.blog_sg.security_group_id]
  tags = {
    Name = "Learning Terraform"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules = ["http-8080-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  name = "blog"
  description = "Security group for blog"
}