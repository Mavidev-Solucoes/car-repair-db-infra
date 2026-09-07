terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "s3" {
    # Backend será configurado via backend-config durante init
    # bucket = "seu-bucket-terraform"
    # key    = "car-repair-db-infra/terraform.tfstate"
    # region = "us-east-1"
    # encrypt = true
  }
}
