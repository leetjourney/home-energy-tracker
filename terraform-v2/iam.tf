resource "aws_iam_role" "app_instance" {
  name = "${var.project}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Project = var.project
  }
}

# SSM access instead of SSH - same pattern as v1.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Pull images from ECR at boot.
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Read the app secrets bundle - scoped to this one secret, nothing else.
resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.project}-secrets-read"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.app.arn
    }]
  })
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${var.project}-instance-profile"
  role = aws_iam_role.app_instance.name
}
