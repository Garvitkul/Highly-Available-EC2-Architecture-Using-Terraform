provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "hyperverge-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Company = "hyperverge"
  }
}

resource "aws_internet_gateway" "hyperverge-igw" {
  vpc_id = aws_vpc.hyperverge-vpc.id

  tags = {
    Company = "hyperverge"
  }
}

resource "aws_subnet" "hyperverge-pub-subnet-1a" {
  vpc_id                  = aws_vpc.hyperverge-vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Company = "hyperverge"
  }
}

resource "aws_subnet" "hyperverge-pub-subnet-1b" {
  vpc_id                  = aws_vpc.hyperverge-vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Company = "hyperverge"
  }
}

resource "aws_route_table" "hyperverge-pub-rt" {
  vpc_id = aws_vpc.hyperverge-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hyperverge-igw.id
  }

  tags = {
    Company = "hyperverge"
  }
}

resource "aws_route_table_association" "hyperverge-rt-assoc-1a" {
  subnet_id      = aws_subnet.hyperverge-pub-subnet-1a.id
  route_table_id = aws_route_table.hyperverge-pub-rt.id
}

resource "aws_route_table_association" "hyperverge-rt-assoc-1b" {
  subnet_id      = aws_subnet.hyperverge-pub-subnet-1b.id
  route_table_id = aws_route_table.hyperverge-pub-rt.id
}

resource "aws_security_group" "hyperverge-autoscaling-sg" {
  name        = "hyperverge-autoscaling-sg"
  description = "AutoScaling-Security-Group-1"
  vpc_id      = aws_vpc.hyperverge-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "hyperverge-key" {
  key_name   = "hyperverge-key"
  public_key = tls_private_key.hyperverge-key.public_key_openssh
}

resource "tls_private_key" "hyperverge-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_launch_configuration" "hyperverge-lc" {
  name                        = "hyperverge-lc"
  image_id                    = "ami-04e5276ebb8451442"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.hyperverge-key.key_name
  security_groups             = [aws_security_group.hyperverge-autoscaling-sg.id]
  associate_public_ip_address = true
  enable_monitoring           = false
  ebs_optimized               = false

  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    MAC_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)

    sudo yum -y install httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd

    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Instance Information</title>
    </head>
    <body>
      <h1>Instance Information</h1>
      <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
      <p><strong>IP Address:</strong> $PRIVATE_IP</p>
      <p><strong>MAC Address:</strong> $MAC_ADDRESS</p>
    </body>
    </html>
    HTML

    sudo systemctl restart httpd
  EOF
}

resource "aws_autoscaling_group" "hyperverge-asg" {
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.hyperverge-lc.name
  max_size                  = 4
  min_size                  = 2
  name                      = "hyperverge-asg"
  vpc_zone_identifier       = [aws_subnet.hyperverge-pub-subnet-1a.id, aws_subnet.hyperverge-pub-subnet-1b.id]
}

resource "aws_lb_target_group" "hyperverge-tg" {
  name     = "hyperverge-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.hyperverge-vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "hyperverge-lb-listener" {
  load_balancer_arn = aws_lb.hyperverge-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hyperverge-tg.arn
  }
}

resource "aws_lb" "hyperverge-lb" {
  name               = "hyperverge-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.hyperverge-alb-sg.id]
  subnets            = [aws_subnet.hyperverge-pub-subnet-1a.id, aws_subnet.hyperverge-pub-subnet-1b.id]
}

resource "aws_security_group" "hyperverge-alb-sg" {
  name        = "hyperverge-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.hyperverge-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  
}

resource "aws_autoscaling_attachment" "hyperverge-asg-attachment-1a" {
  depends_on              = [aws_lb_target_group.hyperverge-tg]
  autoscaling_group_name  = aws_autoscaling_group.hyperverge-asg.name
  lb_target_group_arn     = aws_lb_target_group.hyperverge-tg.arn
}

resource "aws_autoscaling_attachment" "hyperverge-asg-attachment-1b" {
  depends_on              = [aws_lb_target_group.hyperverge-tg]
  autoscaling_group_name  = aws_autoscaling_group.hyperverge-asg.name
  lb_target_group_arn     = aws_lb_target_group.hyperverge-tg.arn
