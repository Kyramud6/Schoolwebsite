locals {
    cloudfront_origin_id = "${"var.projectname}-${var.environment}-alb-origin"

}

resource "aws_cloudfront_distribution" "wordpress" {
    enabled = true
    is_ipv6_enabled = true
    comment = $"{var.projectname}-${var.environment} Wordpress CDN"
    default_root_object "index.php"
    price_class = "PriceClass_100"

    origin {
        domain_name = var.lb_dns_name
        origin_id = local.cloudfront_origin_id

        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocol = ["TLSv1.2]
        }
    }

    default_cache_behaviour {
        target_origin_id = local.cloudfront_origin_id
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = {"DELETE", "GET", "HEAD", "OPTIONS" , "PATCH", "POST", "PUT"}
        cached_methods = ["GET","HEAD"]
        compress = true

        cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
        origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }

    ordered_cache_behavior {
        path_pattern = "wp-content/*"
        target_origin_id = local.cloudfront_origin_id
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = {"DELETE", "GET", "HEAD", "OPTIONS" , "PATCH", "POST", "PUT"}
        cached_methods = ["GET","HEAD"]
        compress = true

        cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
        origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }

    ordered_cache_behavior {
        path_pattern = "wp-includes/*"
        target_origin_id = local.cloudfront_origin_id
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = {"DELETE", "GET", "HEAD", "OPTIONS" , "PATCH", "POST", "PUT"}
        cached_methods = ["GET","HEAD"]
        compress = true

        cache_policy_id "658327ea-f89d-4fab-a63d-7e88639e58f6"
        origin_request_policy_id "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true 
        minimum_protocol_version = "TLSv1.2_2021"
    }

    tags = {
        Name = "${var.projectname}-${var.environment}-cloudfront"
    }

}