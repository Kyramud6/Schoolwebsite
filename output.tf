output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = module.loadbalancer.lb_dns_name
}

output "cloudfront_domain_name" {
  description = "HTTPS hostname assigned to the CloudFront distribution."
  value       = module.cloudfront.domain_name
}

output "aws_cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = module.cloudfront.distribution_id
}

output "database_address" {
  description = "Private DNS address of the RDS MySQL instance."
  value       = module.database.database_address
}

output "database_secret_arn" {
  description = "Secrets Manager ARN containing RDS-managed master credentials."
  value       = module.database.master_secret_arn
}

output "autoscaling_group_name" {
  description = "Name of the WordPress Auto Scaling group."
  value       = module.compute.autoscaling_group_name
}