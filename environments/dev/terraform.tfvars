# Development Environment Terraform Variables

aws_region  = "us-east-1"
environment = "dev"
project_name = "car-repair-db"

# VPC and Network Configuration
vpc_id = "vpc-xxxxxxxxx"  # Replace with your dev VPC ID
private_subnet_ids = [
  "subnet-xxxxxxxxx",  # Replace with your first private subnet
  "subnet-yyyyyyyyy"   # Replace with your second private subnet
]
eks_security_group_id = "sg-xxxxxxxxx"  # Replace with your EKS security group

# Database Configuration
db_name     = "carrepairdb_dev"
db_username = "postgres"
db_password = "ChangeMe@DevPassword123"  # MUST be changed - use strong password

# Instance Configuration
db_instance_class      = "db.t3.micro"  # Smaller for dev
db_allocated_storage   = 20
db_max_allocated_storage = 50

# Backup and Maintenance
backup_retention_days = 7
backup_window        = "03:00-04:00"
maintenance_window   = "sun:04:00-sun:05:00"

# Monitoring
enable_monitoring            = true
monitoring_interval          = 60
enable_performance_insights  = false  # Disabled for cost savings in dev

# Tags
tags = {
  Environment = "dev"
  Team        = "Platform"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
}
