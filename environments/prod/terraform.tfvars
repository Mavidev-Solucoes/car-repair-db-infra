# Production Environment Terraform Variables

aws_region  = "us-east-1"
environment = "prod"
project_name = "car-repair-db"

# VPC and Network Configuration
vpc_id = "vpc-yyyyyyyyy"  # Replace with your prod VPC ID
private_subnet_ids = [
  "subnet-zzzzzzzzz",  # Replace with your first private subnet
  "subnet-wwwwwwwww"   # Replace with your second private subnet
]
eks_security_group_id = "sg-yyyyyyyyy"  # Replace with your EKS security group

# Database Configuration
db_name     = "carrepairdb_prod"
db_username = "postgres"
db_password = "ChangeMe@ProdPassword123!Secure"  # MUST be changed - use very strong password

# Instance Configuration (larger for production)
db_instance_class      = "db.t3.small"  # Minimum recommended for production
db_allocated_storage   = 100
db_max_allocated_storage = 500

# Backup and Maintenance
backup_retention_days = 30  # Longer retention for production
backup_window        = "02:00-03:00"
maintenance_window   = "sun:03:00-sun:04:00"

# Monitoring
enable_monitoring            = true
monitoring_interval          = 10  # More frequent monitoring
enable_performance_insights  = true

# Tags
tags = {
  Environment = "prod"
  Team        = "Platform"
  CostCenter  = "Production"
  ManagedBy   = "Terraform"
  Compliance  = "Required"
}
