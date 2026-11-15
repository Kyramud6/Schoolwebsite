variable "lb_dns_name" {
    description = "DNS Hostname for CloudFront."
    type = string
}

variable "projectname" {
    description = "Project name"
    type = string
}

variable "environment" {
    description = "Deployment environment"
    type = string
}