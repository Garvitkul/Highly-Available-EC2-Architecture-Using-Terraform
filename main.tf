provider "aws" {
  region     = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
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
    vpc_id = "${aws_vpc.hyperverge-vpc.id}"
    tags = {
        Company = "hyperverge"
    }
}
resource "aws_subnet" "hyperverge-pub-subnet" {
    vpc_id                  = "${aws_vpc.hyperverge-vpc.id}"
    cidr_block              = "10.0.10.0/24"
    availability_zone       = "us-east-1a
    map_public_ip_on_launch = false
    tags = {
        Company = "hyperverge"
    }
}
resource "aws_route_table" "hyperverge-pub-rt" {
    vpc_id     = "${aws_vpc.hyperverge-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.hyperverge-igw.id}"
    }
    tags = {
        Company = "hyperverge"
    }
}
resource "aws_route_table_association" "hyperverge-rt-association" {
  subnet_id      = "${aws_subnet.hyperverge-pub-subnet.id}"
  route_table_id = "${aws_route_table.hyperverge-pub-rt.id}"
}
resource "aws_security_group" "hyperverge-autoscaling-sg" {
    name        = "hyperverge-autoscaling-sg"
    description = "AutoScaling-Security-Group-1"
    vpc_id      = "${aws_vpc.hyperverge-vpc.id}
    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}
resource "aws_launch_configuration" "hyperverge-lc" {
    name                        = "hyperverge-lc"
    image_id                    = "ami-04b70fa74e45c3917"
    instance_type               = "t2.micro"
    key_name                    = "hyperverge-key"
    security_groups             = ["${aws_security_group.hyperverge-autoscaling-sg.id}"]
    enable_monitoring           = false
    ebs_optimized               = false
    root_block_device {
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = true
    }
}
resource "aws_elb" "hyperverge-lb" {
    name                        = "hyperverge-lb"
    subnets                     = ["${aws_subnet.hyperverge-pub-subnet.id}"]
    security_groups             = ["${aws_security_group.hyperverge-autoscaling-sg.id}"]
    instances                   = []
    cross_zone_load_balancing   = true
    idle_timeout                = 60
    connection_draining         = true
    connection_draining_timeout = 300
    internal                    = false
    listener {
        instance_port      = 80
        instance_protocol  = "http"
        lb_port            = 80
        lb_protocol        = "http"
        ssl_certificate_id = ""
    }
    health_check {
        healthy_threshold   = 10
        unhealthy_threshold = 2
        interval            = 30
        target              = "HTTP:80/index.html"
        timeout             = 5
    }
    tags = {
        Company = "hyperverge"
    }
}
resource "aws_autoscaling_group" "hyperverge-asg" {
    desired_capacity          = 1
    health_check_grace_period = 300
    health_check_type         = "EC2"
    launch_configuration      = "${aws_launch_configuration.hyperverge-lc.name}"
    max_size                  = 2
    min_size                  = 1
    name                      = "hyperverge-asg"
    vpc_zone_identifier       = ["${aws_subnet.hyperverge-pub-subnet.id}"]
    tag = [
      {
        key   = "Company"
        value = "hyperverge"
        propagate_at_launch = true
      },
      {
        key   = "Name"
        value = "hyperverge-server"
        propagate_at_launch = true
      }
    ]
}