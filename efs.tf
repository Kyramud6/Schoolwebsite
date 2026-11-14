resource "aws_security_group" "efs" {
  name        = "${var.projectname}-${var.environment}-efs"
  description = "File Sharing access for WordPress to EC2s."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.projectname}-${var.environment}-efs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_app" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "EFS application security group"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

resource "aws_vpc_security_group_egress_rule" "app_to_efs" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.efs.id
  description                  = "EFS shared content to Wordpress"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

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
  count = length(aws_subnet.app)

  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.app[count.index].id
  security_groups = [aws_security_group.efs.id]
}

