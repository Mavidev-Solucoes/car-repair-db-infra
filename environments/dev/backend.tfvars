# Backend configuration for Development environment
bucket         = "car-repair-terraform-state-dev"
key             = "car-repair-db-infra/dev/terraform.tfstate"
region          = "us-east-1"
encrypt         = true
dynamodb_table  = "terraform-locks-dev"
