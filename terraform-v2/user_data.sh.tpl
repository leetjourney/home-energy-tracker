#!/bin/bash
set -euo pipefail

# --- Docker ---
apt-get update -y
apt-get install -y ca-certificates curl gnupg jq unzip
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin awscli
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# --- Pull app credentials from Secrets Manager (nothing hardcoded in the AMI) ---
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${secret_arn}" \
  --query SecretString --output text)

MYSQL_ROOT_PASSWORD=$(echo "$SECRET_JSON" | jq -r .MYSQL_ROOT_PASSWORD)
KEYCLOAK_ADMIN_PASSWORD=$(echo "$SECRET_JSON" | jq -r .KEYCLOAK_ADMIN_PASSWORD)
INFLUXDB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .INFLUXDB_PASSWORD)
INFLUX_TOKEN=$(echo "$SECRET_JSON" | jq -r .INFLUX_TOKEN)

# --- App directory ---
APP_DIR=/home/ubuntu/app
mkdir -p "$APP_DIR"
curl -fsSL "${compose_file_url}" -o "$APP_DIR/docker-compose.yml"

cat > "$APP_DIR/.env" <<EOF
ECR_REGISTRY=${ecr_registry}
IMAGE_TAG=${image_tag}
DB_HOST=${db_host}
DB_USERNAME=${db_username}
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD
INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD
INFLUX_TOKEN=$INFLUX_TOKEN
EOF
chown ubuntu:ubuntu "$APP_DIR/.env"

# --- Deploy ---
aws ecr get-login-password --region "${aws_region}" | \
  docker login --username AWS --password-stdin "${ecr_registry}"

cd "$APP_DIR"
docker compose pull
docker compose up -d
