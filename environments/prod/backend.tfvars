# Backend configuration for Production environment
bucket         = "car-repair-terraform-state-prod"
key             = "car-repair-db-infra/prod/terraform.tfstate"
region          = "us-east-1"
encrypt         = true
dynamodb_table  = "terraform-locks-prod"
