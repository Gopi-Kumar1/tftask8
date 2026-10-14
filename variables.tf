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