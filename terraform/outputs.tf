output "instance_public_ip" {
  description = "Elastic IP address of the EC2 instance (stable across stop/start)"
  value       = aws_eip.home_energy_tracker.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.home_energy_tracker.id
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ~/.ssh/home-energy-tracker-key ubuntu@${aws_eip.home_energy_tracker.public_ip}"
}
