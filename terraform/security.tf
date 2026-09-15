# -------------------------------------------------------------------
# RDS Security Group
# -------------------------------------------------------------------

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
}

# -------------------------------------------------------------------
# Database Client Security Group
#
# Reusable by workloads that need PostgreSQL access, including the
# authentication Lambda.
# -------------------------------------------------------------------

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
}

# -------------------------------------------------------------------
# RDS Ingress
# -------------------------------------------------------------------

resource "aws_security_group_rule" "rds_ingress_from_eks_nodes" {
  type = "ingress"

  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.eks_node_security_group_id

  description = "Allow PostgreSQL from EKS worker nodes"
}

resource "aws_security_group_rule" "rds_ingress_from_database_client" {
  type = "ingress"

  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.database_client.id

  description = "Allow PostgreSQL from database client security group"
}

# -------------------------------------------------------------------
# Database Client Egress
# -------------------------------------------------------------------

# PostgreSQL access is restricted specifically to the RDS SG.
resource "aws_security_group_rule" "database_client_egress_to_rds" {
  type = "egress"

  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  security_group_id        = aws_security_group.database_client.id
  source_security_group_id = aws_security_group.rds.id

  description = "Allow PostgreSQL egress to RDS security group"
}

# Lambda needs HTTPS access to AWS APIs such as Secrets Manager.
#
# In AWS Academy the private subnets reach those public AWS endpoints
# through the NAT Gateway.
#
# A production environment can later replace this path with VPC
# Interface Endpoints for tighter network isolation.
resource "aws_security_group_rule" "database_client_https_egress" {
  type = "egress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id = aws_security_group.database_client.id
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Allow HTTPS access to AWS service APIs through NAT"
}

# -------------------------------------------------------------------
# RDS Subnet Group
# -------------------------------------------------------------------

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
}

# -------------------------------------------------------------------
# RDS Enhanced Monitoring IAM Role
#
# Disabled in AWS Academy because IAM role creation is restricted.
# -------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name = "${local.resource_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }

        Action = "sts:AssumeRole"
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

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}