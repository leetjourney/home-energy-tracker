data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    aws_region       = var.aws_region
    ecr_registry     = var.ecr_registry
    image_tag        = var.image_tag
    db_host          = aws_db_instance.main.address
    db_username      = var.db_username
    secret_arn       = aws_secretsmanager_secret.app.arn
    compose_file_url = "https://raw.githubusercontent.com/JuniorZ-spec/home-energy-tracker/master/docker-compose.v2.yml"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-app"
      Project = var.project
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id

  min_size         = var.asg_desired_capacity
  max_size         = var.asg_desired_capacity + 1
  desired_capacity = var.asg_desired_capacity

  # Full stack (Kafka + Keycloak + 7 JVM services) needs time to pull images
  # and boot on a t3.small - a short grace period would cause the ASG to
  # kill healthy-but-still-starting instances.
  health_check_type         = "ELB"
  health_check_grace_period = 600

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
