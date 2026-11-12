resource "aws_db_subnet_group" "main" {
    name = "${var.projectname}-${var.environment}-db-subnets"
    description = "Private data subnets for WordPress Database
    subnet_ids = aws_subnet.data[*].id

    tags = {
        Name = "${var.projectname}-${var.environment}-db-subnets"
    }
}

resource "aws_db_instance" "wordpress" {
    identifier = "${var.projectname}-${var.environment}-mysql"

    engine = "mysql"
    engine_version = var.db_ver"
    instance_class = var.db_instance
    allocated_storage = 20
    max_allocated_storage = 100
    storage_type = "gp3"
    storage_encrpyted = true

    db_name = var.db_name
    username = var.db_username

    manage_master_user_password = true
    port = 3306

    db_subnet_group_name = aws_db_subnet_group.main.name
    aws_vpc_security_group_ids = {aws_security_group.database.id}
    public_accessible = false

    multiple_az = var.az_zone_db
    backup_retention_period = 7
    auto_minor_version_upgrade = true


    delete_protection = var.environment == "prod"
    skip_final_snapshot = var.environment != "prod"
    final_snapshot_identifier = var.environment == "prod" ? "${var.projectname}-${var.environment}-final : null

    tags = {
        Name "${var.projectname}-${var.environment}-mysql"
    }
}

output "database_address" {
    description = "Private DNS Address of RDS MySQL"
    value = aws_db_instance.wordpress.address
}

output "database_name" {
    description = "WordPress db name"
    value = aws_db_instance.wordpress.address
}

output "database_secret_arn" {
    description = "Secret manager ARN for the db"
    value = aws_db_instance.wordpress.master_user_secret[0].sercet_arn
}