resource "aws_db_subnet_group" "main" {
  name        = "${var.projectname}-${var.environment}-db-subnets"
  description = "Private data subnets for WordPress Database"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.projectname}-${var.environment}-db-subnets"
  }
}

resource "aws_db_instance" "wordpress" {
  identifier = "${var.projectname}-${var.environment}-mysql"

  engine                = "mysql"
  engine_version        = var.db_ver
  instance_class        = var.db_instance
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true
  port                        = 3306

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  multi_az                   = var.az_zone_db
  backup_retention_period    = 7
  auto_minor_version_upgrade = true


  deletion_protection       = var.environment == "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.projectname}-${var.environment}-final" : null

  tags = {
    Name = "${var.projectname}-${var.environment}-mysql"
  }
}

