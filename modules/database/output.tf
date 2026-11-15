output "database_address" {
  description = "Private DNS Address of RDS MySQL"
  value       = aws_db_instance.wordpress.address
}

output "database_name" {
  description = "WordPress db name"
  value       = aws_db_instance.wordpress.address
}

output "master_secret_arn" {
  description = "Secret manager ARN for the db"
  value       = aws_db_instance.wordpress.master_user_secret[0].secret_arn
}