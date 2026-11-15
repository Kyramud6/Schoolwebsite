data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${var.projectname}-${var.environment}-alb"
  description = "HTTP access from cloudfront"
  vpc_id      = var.vpc_id

  egress = []
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin.id
  description       = "HTTP from cloudfront facing addresses"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "forward http request to wordpress"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_security_group" "app" {
  name        = "${var.projectname}-${var.environment}-app"
  description = "EC2 Instance will be limited the inbound by Load Balancer"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
    security_group_id = aws_security_group.app.id
    referenced_security_group_id = aws_security_group.alb.id
    ip_protocol = "tcp"
    from_port = 80
    to_port = 80
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
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.projectname}-${var.environment}-database-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "Mysql security group for WordPress"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "app_mysql" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.database.id
  description                  = "Mysql security group for WordPress"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306  
}


resource "aws_security_group" "efs" {
  name        = "${var.projectname}-${var.environment}-efs"
  description = "File Sharing access for WordPress to EC2s."
  vpc_id      = var.vpc_id

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

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront_https" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin.id
  description       = "HTTPS from CloudFront"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}