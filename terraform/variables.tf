variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix used on all resources"
  type        = string
  default     = "devops-demo"
}

variable "instance_type" {
  description = "EC2 instance type. t3.small is enough for k3s + Jenkins in a demo."
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Name of an EXISTING EC2 key pair in your AWS account, used for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your public IP in CIDR form, e.g. 49.36.XX.XX/32 - used to restrict SSH access. Get it from whatismyip.com"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
