# Production Environment Terraform Variables

aws_region  = "us-east-1"
environment = "prod"

# VPC and Network Configuration
vpc_id = "vpc-yyyyyyyyy" # Replace with car-repair-k8s-infra prod output vpc_id
private_subnet_ids = [
  "subnet-zzzzzzzzz", # Replace with car-repair-k8s-infra prod output private_subnets[0]
  "subnet-wwwwwwwww"  # Replace with car-repair-k8s-infra prod output private_subnets[1]
]
eks_node_security_group_id = "sg-yyyyyyyyy" # Replace with car-repair-k8s-infra prod output node_security_group_id

# Database Configuration
db_name     = "carrepairdb_prod"
db_username = "postgres"

# Instance Configuration (larger for production)
db_instance_class        = "db.t3.small" # Minimum recommended for production
db_allocated_storage     = 100
db_max_allocated_storage = 500

# Backup and Maintenance
backup_retention_days = 30 # Longer retention for production
backup_window         = "02:00-03:00"
maintenance_window    = "sun:03:00-sun:04:00"

# Monitoring
enable_monitoring           = true
monitoring_interval         = 10 # More frequent monitoring
enable_performance_insights = true

# Tags
tags = {
  Team       = "Platform"
  CostCenter = "Production"
  Compliance = "Required"
}
