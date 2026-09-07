output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgresql.endpoint
  sensitive   = false
}

output "rds_hostname" {
  description = "RDS PostgreSQL hostname (without port)"
  value       = aws_db_instance.postgresql.address
  sensitive   = false
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgresql.port
  sensitive   = false
}

output "rds_database_name" {
  description = "RDS PostgreSQL database name"
  value       = aws_db_instance.postgresql.db_name
  sensitive   = false
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.postgresql.arn
  sensitive   = false
}

output "rds_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.postgresql.resource_id
  sensitive   = false
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
  sensitive   = false
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.default.name
  sensitive   = false
}

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN for database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = false
}

output "secrets_manager_secret_name" {
  description = "Secrets Manager secret name for database credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
  sensitive   = false
}

output "rds_connection_string" {
  description = "Connection string for the RDS database (for reference only)"
  value       = "postgresql://${var.db_username}:***@${aws_db_instance.postgresql.address}:${aws_db_instance.postgresql.port}/${aws_db_instance.postgresql.db_name}"
  sensitive   = true
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "backup_retention_days" {
  description = "Number of days backups are retained"
  value       = aws_db_instance.postgresql.backup_retention_period
}

output "auto_minor_version_upgrade" {
  description = "Whether automatic minor version upgrade is enabled"
  value       = aws_db_instance.postgresql.auto_minor_version_upgrade
}

output "storage_type" {
  description = "Storage type (gp3, io1, etc)"
  value       = aws_db_instance.postgresql.storage_type
}

output "allocated_storage" {
  description = "Currently allocated storage in GB"
  value       = aws_db_instance.postgresql.allocated_storage
}

output "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  value       = aws_db_instance.postgresql.max_allocated_storage
}
