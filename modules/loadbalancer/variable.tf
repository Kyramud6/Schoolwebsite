variable "public_subnet_ids" {
    description = "Public subnet ids for ALB."
    type = list(string)
}

variable "security_group_id" {
    description = "security group allow for cloudfront traffic."
    type = string
}

variable "vpc_id" {
    description = "vpn id used for the target group"
    type = string
}

variable "projectname" {
    type = string
}

variable "environment" {
    type = string
}