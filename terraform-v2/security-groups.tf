resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allow inbound HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-alb-sg"
    Project = var.project
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "ASG instances - api-gateway only reachable from the ALB, no SSH (SSM access instead)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "api-gateway from ALB"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-app-sg"
    Project = var.project
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "MySQL only reachable from the app tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from app instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-rds-sg"
    Project = var.project
  }
}
