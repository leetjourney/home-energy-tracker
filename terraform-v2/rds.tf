resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Project = var.project
  }
}

# Deliberate choices for an ephemeral verification resource, not oversights:
#  - deletion_protection=false / skip_final_snapshot=true so `terraform
#    destroy` tears this down cleanly right after verification
#  - backup_retention_period=1 (AWS minimum) since it never lives long
#    enough for backups to matter
#  - IAM database authentication and Performance Insights are real
#    production hardening, left out here as out of scope for a demo
#tfsec:ignore:aws-rds-specify-backup-retention
#tfsec:ignore:aws-rds-enable-performance-insights
#tfsec:ignore:aws-rds-enable-iam-auth
resource "aws_db_instance" "main" {
  identifier     = "${var.project}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 1
  skip_final_snapshot     = true # demo resource, no need to keep a snapshot on destroy
  #tfsec:ignore:aws-rds-enable-deletion-protection
  deletion_protection = false

  tags = {
    Name    = "${var.project}-mysql"
    Project = var.project
  }
}
