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

data "aws_vpc" "default" {
  default = true
}


resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.blog.id]
  tags = {
    Name = "Learning Terraform"
  }
}

resource "aws_security_group" "blog" {
  name = "blog"
  vpc_id = data.aws_vpc.default.id
  tags = {
    name = "blog"
  }
}

resource "aws_security_group_rule" "blog_http_in" {

  type = "ingress"
  to_port = "8080"
  from_port = "8080"
  protocol = "http"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "https"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group" "blog_everything_out" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.blog.id
}
