output "cloudfront_domain_name" {
    description = "HTTP domain name assigned to cloudfront distribution"
    value = aws_cloudfront_distribution.wordpress.domain_name
}

output "aws_cloudfront_distribution_id" {
    description = "ID of Cloudfront distribution."
    value = aws_cloudfront_distribution.wordpress.id
}