# Car Repair Database Infrastructure

Terraform configuration for provisioning Amazon RDS PostgreSQL 17 on AWS following production-oriented best practices for the FIAP Tech Challenge, with decoupled network integration for EKS, Kong, Lambda and observability tooling such as New Relic.

## 📋 Project Overview

This repository contains Infrastructure as Code (IaC) using Terraform to deploy and manage:

- **Amazon RDS PostgreSQL 17** instance
- **AWS Secrets Manager** for credential management
- **Security Groups** for network isolation
- **DB Subnet Groups** for multi-AZ deployment
- **Automated Backups** with 7-day retention
- **Storage Autoscaling** for dynamic capacity management
- **Enhanced Monitoring** with CloudWatch
- **Performance Insights** for database optimization

## 🏗️ Architecture

```
┌─────────────────────┐
│   EKS Cluster       │
│  (.NET Application) │
└──────────┬──────────┘
           │
           │ (Security Group)
           ▼
┌─────────────────────┐
│  RDS PostgreSQL 17  │
│  - Multi-AZ         │
│  - Encryption       │
│  - Monitoring       │
│  - Auto-backup      │
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│ AWS Secrets Manager │
│ (DB Credentials)    │
└─────────────────────┘
```

## 📁 Directory Structure

```
car-repair-db-infra/
├── terraform/
│   ├── provider.tf          # AWS provider configuration
│   ├── versions.tf          # Terraform and provider versions
│   ├── variables.tf         # Input variables with validation
│   ├── outputs.tf           # Output values for integration
│   ├── rds.tf              # RDS PostgreSQL instance configuration
│   ├── security.tf         # Security groups, subnet groups, IAM roles
│   └── secrets.tf          # Secrets Manager configuration
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars    # Dev environment variables
│   │   └── backend.tfvars      # Dev state backend configuration
│   └── prod/
│       ├── terraform.tfvars    # Prod environment variables
│       └── backend.tfvars      # Prod state backend configuration
├── .gitignore              # Git ignore rules
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.12
- AWS CLI configured with appropriate credentials
- AWS Account with necessary permissions
- Existing VPC with private subnets
- At least one application security group that should be allowed to reach PostgreSQL

### Setup Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/Mavidev-Solucoes/car-repair-db-infra.git
cd car-repair-db-infra
```

#### 2. Create S3 Bucket for Terraform State (if not exists)

```bash
# For Development
aws s3api create-bucket \
  --bucket car-repair-terraform-state-dev \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket car-repair-terraform-state-dev \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket car-repair-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Repeat for Production with 'prod' suffix
```

#### 3. Update Environment Variables

**For Development:**

```bash
vi environments/dev/terraform.tfvars
```

Update the following variables:
- `vpc_id`: Your VPC ID
- `private_subnet_ids`: Your private subnet IDs
- `allowed_security_groups`: Security groups from approved consumers (EKS, Kong, Lambda, bastion, etc.)

**For Production:**

```bash
vi environments/prod/terraform.tfvars
```

Update the same variables with production values. The master password is generated automatically, stored in AWS Secrets Manager and consumed by RDS during provisioning.

#### 4. Initialize Terraform

**For Development:**

```bash
cd terraform
terraform init \
  -backend-config=../environments/dev/backend.tfvars
```

**For Production:**

```bash
cd terraform
terraform init \
  -backend-config=../environments/prod/backend.tfvars
```

#### 5. Plan the Deployment

```bash
terraform plan \
  -var-file=../environments/dev/terraform.tfvars \
  -out=dev.tfplan
```

#### 6. Apply the Configuration

```bash
terraform apply dev.tfplan
```

## 📊 Outputs

After successful deployment, Terraform outputs include:

- `rds_endpoint`: Connection endpoint (host:port)
- `rds_hostname`: Database hostname
- `rds_port`: PostgreSQL port (5432)
- `rds_database_name`: Initial database name
- `rds_arn`: RDS instance ARN
- `endpoint`: Simplified endpoint output
- `port`: Simplified port output
- `arn`: Simplified ARN output
- `secret_arn`: Simplified secret ARN output
- `security_group_id`: RDS security group ID
- `secrets_manager_secret_arn`: Secrets Manager ARN
- `secrets_manager_secret_name`: Secrets Manager secret name
- `rds_connection_string`: Full connection string (sensitive)

## 🔐 Security Features

- ✅ **Encryption at Rest**: EBS volumes encrypted
- ✅ **Encryption in Transit**: SSL/TLS enabled
- ✅ **Secrets Manager Integration**: Database credentials generated automatically and stored securely
- ✅ **Security Group**: Restricted ingress from approved security groups only
- ✅ **Multi-AZ Deployment** (Prod): High availability
- ✅ **IAM Database Authentication**: Optional IAM-based access
- ✅ **Automated Backups**: 7-day retention (configurable)
- ✅ **Enhanced Monitoring**: Real-time performance insights

## 📈 Backup & Recovery Strategy

### Development Environment
- Backup Retention: 7 days
- Backup Window: 03:00-04:00 UTC
- Skip Final Snapshot: Yes (to reduce costs)

### Production Environment
- Backup Retention: 30 days
- Backup Window: 02:00-03:00 UTC
- Skip Final Snapshot: No (final snapshot created)
- Deletion Protection: Enabled

## 🔄 Storage Autoscaling

- **Dev**: Allocates 20GB, scales up to 50GB
- **Prod**: Allocates 100GB, scales up to 500GB
- Autoscaling enabled with gp3 storage type

## 📝 PostgreSQL Configuration

- **Version**: PostgreSQL 17
- **Parameter Group**: Optimized for .NET applications
- **Logging**: DDL statements logged, queries >1000ms logged
- **Max Connections**: 200 (dev), 500 (prod)
- **Performance Tuning**: Shared preload libraries, work_mem, maintenance_work_mem

## 🛠️ Common Commands

```bash
# Plan changes
terraform plan -var-file=../environments/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=../environments/dev/terraform.tfvars

# Destroy infrastructure (WARNING: Irreversible)
terraform destroy -var-file=../environments/dev/terraform.tfvars

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Show state
terraform show

# Get specific output
terraform output rds_endpoint
```

## 📚 Retrieving Database Credentials

Retrieve database credentials from Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id car-repair-db-credentials-xxxxx \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

## 🚨 Important Notes

1. **Database Password**: Terraform generates the master password and writes it to Secrets Manager automatically
2. **Network Access**: Populate `allowed_security_groups` with every approved client security group
3. **State File Security**: Terraform state contains sensitive data. Keep S3 bucket encrypted and versioned
4. **Backup Testing**: Regularly test database restoration from backups
5. **Monitoring**: Set up CloudWatch alarms for CPU, memory, and storage
6. **Compliance**: Review and adjust retention policies according to your compliance requirements

## 📞 Troubleshooting

### RDS Instance Creation Fails

```bash
# Check if subnets are in different AZs
aws ec2 describe-subnets --subnet-ids subnet-xxx --query 'Subnets[].AvailabilityZone'
```

### Cannot Connect to Database

```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids sg-xxx

# Check RDS status
aws rds describe-db-instances --db-instance-identifier car-repair-db-pg-xxxxx
```

### Secrets Manager Access Issues

```bash
# List secrets
aws secretsmanager list-secrets --region us-east-1
```

## 📖 Additional Resources

- [AWS RDS PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/)

## 📄 License

This project is part of the Tech Challenge course at FIAP.

## ✍️ Authors

- Mavidev Soluções

---

**Last Updated**: September 2026
**Terraform Version**: >= 1.12
**AWS Provider Version**: >= 5.40
