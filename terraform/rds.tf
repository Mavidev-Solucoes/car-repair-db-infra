# RDS PostgreSQL Instance
resource "aws_db_instance" "postgresql" {
  identifier = "${local.resource_prefix}-postgresql"

  # Database Engine
  engine         = "postgres"
  engine_version = local.db_engine_version

  # Instance Configuration
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.environment == "prod" ? true : false

  # Backup Configuration
  backup_retention_period   = var.backup_retention_days
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = var.environment == "dev"
  final_snapshot_identifier = var.environment == "prod" ? "${local.resource_prefix}-pg-final-snapshot" : null

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = true
  deletion_protection        = var.environment == "prod"

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = var.enable_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn             = var.enable_monitoring ? aws_iam_role.rds_monitoring.arn : null

  # Performance Insights
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? 7 : null

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgresql.name

  # Other
  iam_database_authentication_enabled = true
  allow_major_version_upgrade         = false
  apply_immediately                   = var.environment == "dev"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-postgresql"
    }
  )

  depends_on = [
    aws_db_subnet_group.default,
    aws_security_group.rds,
    aws_iam_role.rds_monitoring
  ]
}

# RDS Parameter Group for PostgreSQL 17
resource "aws_db_parameter_group" "postgresql" {
  name        = "${local.resource_prefix}-pg17"
  family      = local.db_parameter_group_family
  description = "Parameter group for ${local.resource_prefix} PostgreSQL ${local.db_engine_version}"

  # Performance tuning for .NET applications
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "max_connections"
    value = var.environment == "prod" ? "500" : "200"
  }

  parameter {
    name  = "work_mem"
    value = "16384" # 16MB
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "262144" # 256MB
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-pg-parameter-group"
    }
  )
}

# RDS Cluster Event Subscription (optional)
resource "aws_db_event_subscription" "rds_events" {
  name      = "${local.resource_prefix}-rds-events"
  sns_topic = aws_sns_topic.rds_alerts.arn

  source_type = "db-instance"
  enabled     = true

  event_categories = [
    "availability",
    "backup",
    "configuration change",
    "database instance",
    "failover",
    "failure",
    "maintenance",
    "notification",
    "recovery"
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-events"
    }
  )
}

# SNS Topic for RDS Alerts
resource "aws_sns_topic" "rds_alerts" {
  name = "${local.resource_prefix}-rds-alerts"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-alerts"
    }
  )
}

# Enhanced Monitoring log group
resource "aws_cloudwatch_log_group" "rds_enhanced_monitoring" {
  name              = "/aws/rds/enhanced-monitoring/${local.resource_prefix}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-enhanced-monitoring"
    }
  )
}
