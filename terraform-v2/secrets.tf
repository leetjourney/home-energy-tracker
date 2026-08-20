resource "random_password" "db" {
  length  = 24
  special = false # avoid characters MySQL/JDBC URLs choke on
}

resource "random_password" "keycloak_admin" {
  length  = 20
  special = false
}

resource "random_password" "influxdb_admin" {
  length  = 20
  special = false
}

resource "random_password" "influx_token" {
  length  = 32
  special = false
}

# Single JSON secret for all app credentials, fetched by the instances at
# boot via their IAM role - nothing is hardcoded in the AMI/user_data,
# matching the "no stored credentials" pattern used on the Save Money project.
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}-app-secrets"
  recovery_window_in_days = 0 # demo resource, allow immediate deletion on destroy

  tags = {
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    MYSQL_ROOT_PASSWORD    = random_password.db.result
    KEYCLOAK_ADMIN_PASSWORD = random_password.keycloak_admin.result
    INFLUXDB_PASSWORD      = random_password.influxdb_admin.result
    INFLUX_TOKEN           = random_password.influx_token.result
  })
}
