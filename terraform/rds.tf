# RDS PostgreSQL Instance
resource "aws_db_instance" "postgresql" {
  identifier_prefix = "${var.project_name}-pg-"

  # Database Engine
  engine               = "postgres"
  engine_version       = "17.1"
  family               = "postgres17"
  major_engine_version = "17"

  # Instance Configuration
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true
  iops                 = 3000
  storage_throughput   = 125

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.environment == "prod" ? true : false

  # Backup Configuration
  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-pg-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Maintenance
  maintenance_window           = var.maintenance_window
  auto_minor_version_upgrade   = true
  deletion_protection          = var.environment == "prod" ? true : false
  skip_final_snapshot          = var.environment == "dev" ? true : false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval              = var.enable_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn              = var.enable_monitoring ? aws_iam_role.rds_monitoring.arn : null

  # Performance Insights
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? 7 : null

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgresql.name

  # Other
  iam_database_authentication_enabled = true
  enable_iam_database_authentication  = true
  enable_http_endpoint                = false
  allow_major_version_upgrade         = false
  apply_immediately                   = var.environment == "dev" ? true : false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-postgresql-${var.environment}"
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
  name_prefix = "${var.project_name}-pg17-"
  family      = "postgres17"
  description = "Parameter group for ${var.project_name} PostgreSQL 17"

  # Performance tuning for .NET applications
  parameter {
    name  = "log_statement"
    value = "all"
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
    var.tags,
    {
      Name = "${var.project_name}-pg-parameter-group"
    }
  )
}

# RDS Cluster Event Subscription (optional)
resource "aws_db_event_subscription" "rds_events" {
  name      = "${var.project_name}-rds-events"
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
    var.tags,
    {
      Name = "${var.project_name}-rds-events"
    }
  )
}

# SNS Topic for RDS Alerts
resource "aws_sns_topic" "rds_alerts" {
  name_prefix = "${var.project_name}-rds-alerts-"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-alerts"
    }
  )
}

# Enhanced Monitoring log group
resource "aws_cloudwatch_log_group" "rds_enhanced_monitoring" {
  name_prefix       = "/aws/rds/enhanced-monitoring/${var.project_name}-"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-enhanced-monitoring"
    }
  )
}
