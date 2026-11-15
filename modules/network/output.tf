output "vpc_id" {
  description = "ID of VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnet IDs for EC2."
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Private data subnet IDs for RDS."
  value       = aws_subnet.data[*].id
}
output "app_subnet_cidrs" {
    description = "Application subnet CIDRs for ACL rules and documentation."
    value = aws_subnet.app[*].cidr_block
}

output "public_subnet_cidrs" {
    description = "Public subnet cidrs for acl rules and documentation."
    value = aws_subnet.public[*].cidr_block
}

output "data_subnet_cidrs" {
    description = "Data subnet cidrs for acl rule and documentation."
    value = aws_subnet.data[*].cidr_block
}