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

# Security Group reused by serverless database clients, such as the auth Lambda.
resource "aws_security_group" "database_client" {
  name        = "${local.resource_prefix}-database-client-sg"
  description = "Reusable client security group for ${local.resource_prefix} database access"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-database-client-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow PostgreSQL traffic from EKS worker nodes.
resource "aws_security_group_rule" "rds_ingress_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.eks_node_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from EKS worker nodes"
}

# Allow PostgreSQL traffic from the reusable serverless client identity.
resource "aws_security_group_rule" "rds_ingress_from_database_client" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database_client.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from database client security group"
}

# Allow serverless clients using the reusable SG to initiate PostgreSQL connections.
resource "aws_security_group_rule" "database_client_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.database_client.id
  description              = "Allow PostgreSQL egress to RDS security group"
}

# DB Subnet Group for RDS placement.
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

# IAM Role used only when RDS Enhanced Monitoring is enabled.
# AWS Academy dev disables Enhanced Monitoring, so no IAM role is created there.
resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_monitoring ? 1 : 0

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

# Attach the AWS managed RDS Enhanced Monitoring policy only when enabled.
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}