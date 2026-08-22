# Internet-facing on purpose: this ALB is the app's single public entry
# point, matching the API Gateway exposure pattern used in v1.
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "app" {
  name                       = "${var.project}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public[*].id
  drop_invalid_header_fields = true

  tags = {
    Project = var.project
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project}-tg"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/actuator/health"
    port                = "9000"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Project = var.project
  }
}

# HTTP only, no ACM cert: this is an ephemeral verification deployment with
# no custom domain to issue a certificate for. HTTPS would be the right
# call for anything longer-lived than a few hours.
#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
