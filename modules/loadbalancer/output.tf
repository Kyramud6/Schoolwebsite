output "lb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.wordpress.dns_name
}

output "lb_zone_id" {
  description = "hosted zone id for the ALB"
  value       = aws_lb.wordpress.zone_id
}

output "target_group_arn" {
    description = "Target group arn for WordPress auto scaling group"
    value = aws_lb_target_group.wordpress.arn
}