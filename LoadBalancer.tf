data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${var.projectname}-${var.environment}-alb"
  description = "HTTP access from cloudfront"
  vpc_id      = aws_vpc.main.id
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

resource "aws_lb" "wordpress" {
  name               = "${var.projectname}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod"

  tags = {
    Name = "Load Balancer ALB"
  }
}

resource "aws_lb_target_group" "wordpress" {
  name        = "${var.projectname}-wp"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id


  depends_on = [
    aws_network_acl_rule.public_ingress,
    aws_network_acl_rule.public_egress
  ]

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/wp-login.php"
    port                = "traffic-port"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.projectname}-wordpress"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.wordpress.dns_name
}

output "alb_zone_id" {
  description = "hosted zone id for the ALB"
  value       = aws_lb.wordpress.zone_id
}
