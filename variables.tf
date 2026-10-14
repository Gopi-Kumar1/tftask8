variable "region" {
  description = "AWS region where the resources are created"
  type        = string
}

variable "project_id" {
  description = "Project identifier used as a prefix for resource names and in the Project tag"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the pre-created VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block of public subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block of public subnet B"
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block of private subnet A"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block of private subnet B"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Launch Template"
  type        = string
}

variable "ssh_sg_name" {
  description = "Name of the pre-created security group that allows SSH access to EC2 instances"
  type        = string
}

variable "http_sg_name" {
  description = "Name of the pre-created security group that allows HTTP access to EC2 instances"
  type        = string
}

variable "lb_sg_name" {
  description = "Name of the pre-created security group attached to the load balancer"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the pre-created IAM instance profile for EC2 instances"
  type        = string
}

variable "launch_template_name" {
  description = "Name of the Launch Template"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "target_group_name" {
  description = "Name of the load balancer target group"
  type        = string
}