locals {
  resource_prefix           = "car-repair-${var.environment}"
  db_engine_version         = "17"
  db_parameter_group_family = "postgres17"

  common_tags = merge(
    var.tags,
    {
      Project     = "car-repair-shop"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "FIAP-TechChallenge"
    }
  )
}
