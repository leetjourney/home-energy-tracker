variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small" # 2GB RAM - needed for 7 JVM services + Kafka + MySQL + InfluxDB + Keycloak
}

variable "public_key_path" {
  description = "Path to your local SSH public key (.pub file)"
  type        = string
  default     = "~/.ssh/home-energy-tracker-key.pub"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, e.g. 82.123.45.67/32 (get it from https://whatismyip.com). No default on purpose: SSH and the admin ports (Grafana/Prometheus/Kafka UI/Mailpit/Keycloak) are scoped to this CIDR, so an unset value would silently open them to the entire internet."
  type        = string
}
