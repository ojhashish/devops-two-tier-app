# terraform/secrets.tf
resource "aws_secretsmanager_secret" "example_secret" {
  name = "${var.project_name}/example-secret-v2"
  description = "An example secret for the application v2"
  # Optional: Add a recovery window in days for deleted secrets
  # recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "example_secret_version" {
  secret_id     = aws_secretsmanager_secret.example_secret.id
  # Store a JSON string of key-value pairs for your secrets
  secret_string = jsonencode({
    "API_KEY" = "your_super_secret_api_key_here",
    "DB_PASSWORD" = "your_db_password_here"
  })
  # This version depends on the secret being created
  depends_on = [aws_secretsmanager_secret.example_secret]
}

# IAM Policy to allow ECS Task Role to read specific secrets
resource "aws_iam_policy" "secrets_read_policy" {
  name        = "${var.project_name}-secrets-read-policy"
  description = "Allows ECS tasks to read secrets from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret" # DescribeSecret is often needed for GetSecretValue
        ],
        Resource = [
          aws_secretsmanager_secret.example_secret.arn # Specific secret ARN
        ]
      }
    ]
  })
}
