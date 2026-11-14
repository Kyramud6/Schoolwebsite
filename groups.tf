resource "aws_security_group" "app" {
  name        = "${var.projectname}-${var.environment}-app"
  description = "EC2 Instance will be limited the inbound by Load Balancer"
  vpc_id      = aws_vpc.main.id

}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS for package repo and external services"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_security_group" "database" {
  name        = "${var.projectname}-${var.environment}-database"
  description = "MySQL access from WordPress only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.projectname}-${var.environment}-database-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_database" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "Mysql security group for WordPress"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}