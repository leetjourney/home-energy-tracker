output "alb_dns_name" {
  description = "Public URL of the load balancer"
  value       = "http://${aws_lb.app.dns_name}"
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (private, not internet-reachable)"
  value       = aws_db_instance.main.endpoint
}

output "rds_multi_az" {
  value = aws_db_instance.main.multi_az
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "vpc_id" {
  value = aws_vpc.main.id
}
