resource "aws_lb" "wordpress" {
  name               = "${var.projectname}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

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
  vpc_id      = var.vpc_id

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
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

locals {
  origin_domain_name = "origin.${var.domain_name}"
}

data "aws_route53_zone" "public" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "origin" {
  domain_name       = local.origin_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "origin_validation" {
  for_each = {
    for option in aws_acm_certificate.origin.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.public.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "origin" {
  certificate_arn = aws_acm_certificate.origin.arn

  validation_record_fqdns = [
    for record in aws_route53_record.origin_validation : record.fqdn
  ]
}

resource "aws_route53_record" "origin" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.origin_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.wordpress.dns_name
    zone_id                = aws_lb.wordpress.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.origin.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

