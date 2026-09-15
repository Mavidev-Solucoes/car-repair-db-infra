# Development Environment Terraform Variables

aws_region  = "us-east-1"
environment = "dev"

# VPC and Network Configuration
vpc_id = "vpc-0436bee2773a39c9c"

private_subnet_ids = [
  "subnet-0bbcfe7d9cec4a577",
  "subnet-09df4c46be8c12546"
]

eks_node_security_group_id = "sg-04b70ea645bca684a"

# Database Configuration
db_name     = "carrepairdb_dev"
db_username = "postgres"

# Instance Configuration
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50

# Backup and Maintenance
backup_retention_days = 7
backup_window         = "03:00-04:00"
maintenance_window    = "sun:04:00-sun:05:00"

# Monitoring
# Disabled in AWS Academy to avoid requiring creation/use of an
# RDS Enhanced Monitoring IAM role.
enable_monitoring           = false
monitoring_interval         = 0
enable_performance_insights = false

# Tags
tags = {
  Team       = "Platform"
  CostCenter = "Engineering"
}