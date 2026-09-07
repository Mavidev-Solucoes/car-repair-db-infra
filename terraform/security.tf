# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.resource_prefix}-rds-sg"
  description = "Security group for ${local.resource_prefix} RDS PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow PostgreSQL traffic from approved application security groups
resource "aws_security_group_rule" "rds_ingress_from_allowed_security_groups" {
  for_each = toset(var.allowed_security_groups)

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from approved application security groups"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# DB Subnet Group for RDS placement
resource "aws_db_subnet_group" "default" {
  name        = "${local.resource_prefix}-db-subnet-group"
  description = "Subnet group for ${local.resource_prefix} RDS"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-db-subnet-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.resource_prefix}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-rds-monitoring-role"
    }
  )
}

# Attach RDS Monitoring Policy
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
