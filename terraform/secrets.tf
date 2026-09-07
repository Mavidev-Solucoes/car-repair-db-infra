resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Secrets Manager Secret for Database Credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.resource_prefix}-db-credentials"
  description             = "Database credentials for ${local.resource_prefix} RDS PostgreSQL"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-db-credentials"
    }
  )
}

# Secret Version with actual credentials
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username            = var.db_username
    password            = random_password.db_password.result
    engine              = "postgres"
    host                = aws_db_instance.postgresql.address
    port                = aws_db_instance.postgresql.port
    dbname              = aws_db_instance.postgresql.db_name
    dbClusterIdentifier = null
  })
}

# CloudWatch Log Group for RDS (optional)
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/${aws_db_instance.postgresql.id}/postgresql"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-logs"
    }
  )
}
