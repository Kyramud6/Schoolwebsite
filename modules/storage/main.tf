resource "aws_efs_file_system" "wordpress" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.projectname}-${var.environment}-wordpress-content"
  }
}

resource "aws_efs_mount_target" "app" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.security_group_id]
}

