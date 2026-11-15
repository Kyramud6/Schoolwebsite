output "alb_security_group_id" {
  description = "security group attached to alb"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "security group attach to ec2"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "security group attached to rds"
  value       = aws_security_group.database.id
}

output "efs_security_group_id" {
  description = "security group attach to efs"
  value       = aws_security_group.efs.id
}