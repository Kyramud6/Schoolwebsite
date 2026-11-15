output "database_address" {
  description = "Private DNS Address of RDS MySQL"
  value       = var.db_address
}

output "database_name" {
  description = "WordPress db name"
  value       = var.db_name
}

output "master_secret_arn" {
  description = "Secret manager ARN for the db"
  value       = var.master_secret_arn
}