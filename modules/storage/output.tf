output "file_system_id" {
  description = "encrypted efs file system id"
  value       = aws_efs_file_system.wordpress.id
}