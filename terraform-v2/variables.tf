variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (ALB, NAT Gateway)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets (ASG, RDS)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "azs" {
  description = "Availability zones to spread the VPC across"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group"
  type        = string
  default     = "t3.small" # 2GB RAM, same sizing as v1 - JVM services + Kafka + InfluxDB + Keycloak
}

variable "asg_desired_capacity" {
  description = "Number of app instances to run across the two AZs"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "home_energy_tracker"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "ecr_registry" {
  description = "ECR registry hostname"
  type        = string
  default     = "915993062361.dkr.ecr.eu-west-3.amazonaws.com"
}

variable "image_tag" {
  description = "Image tag to deploy for all home-energy-tracker microservices"
  type        = string
  default     = "1"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, for restricted admin access (Grafana/Kafka UI/etc. if ever exposed)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project" {
  description = "Project tag applied to every resource"
  type        = string
  default     = "home-energy-tracker-v2"
}
