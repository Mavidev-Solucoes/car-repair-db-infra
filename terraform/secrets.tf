# Secrets Manager Secret for Database Credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.project_name}-db-credentials-"
  description             = "Database credentials for ${var.project_name} RDS PostgreSQL"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-credentials"
    }
  )
}

# Secret Version with actual credentials
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.postgresql.address
    port     = aws_db_instance.postgresql.port
    dbname   = aws_db_instance.postgresql.db_name
    dbClusterIdentifier = null
  })
}

# Secrets Manager Resource Policy (if needed for EKS access)
# Uncomment and modify if using IAM roles for service accounts (IRSA)
resource "aws_secretsmanager_secret_policy" "db_credentials" {
  secret_arn = aws_secretsmanager_secret.db_credentials.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAWSServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for RDS (optional)
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name_prefix       = "/aws/rds/${var.project_name}-"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-logs"
    }
  )
}
