locals {
  vpc_name              = "${var.project_id}-vpc"
  ssh_sg_name           = "${var.project_id}-ec2_sg"
  http_sg_name          = "${var.project_id}-http_sg"
  lb_sg_name            = "${var.project_id}-sglb"
  instance_profile_name = "${var.project_id}-instance_profile"
  key_pair_name         = "${var.project_id}-keypair"
  launch_template_name  = "${var.project_id}-template"
  asg_name              = "${var.project_id}-asg"
  alb_name              = "${var.project_id}-loadbalancer"
  target_group_name     = "${var.project_id}-tg"

  common_tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}


data "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnet" "public_a" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.public_subnet_a_cidr
}

data "aws_subnet" "public_b" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.public_subnet_b_cidr
}

data "aws_security_group" "ssh" {
  vpc_id = data.aws_vpc.main.id
  name   = local.ssh_sg_name
}

data "aws_security_group" "http" {
  vpc_id = data.aws_vpc.main.id
  name   = local.http_sg_name
}

data "aws_security_group" "lb" {
  vpc_id = data.aws_vpc.main.id
  name   = local.lb_sg_name
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_launch_template" "app" {
  name          = local.launch_template_name
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = local.key_pair_name

  iam_instance_profile {
    name = local.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      data.aws_security_group.ssh.id,
      data.aws_security_group.http.id
    ]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd jq
    systemctl enable httpd
    systemctl start httpd

    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

    echo "<h1>This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tags = local.common_tags
}


resource "aws_lb_target_group" "app" {
  name     = local.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}


resource "aws_lb" "app" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [data.aws_security_group.lb.id]
  subnets            = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = local.common_tags
}


resource "aws_autoscaling_group" "app" {
  name                      = local.asg_name
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 2
  vpc_zone_identifier       = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = aws_autoscaling_group.app.id
  lb_target_group_arn    = aws_lb_target_group.app.arn
}