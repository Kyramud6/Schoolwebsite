variable "origin_domain_name" {
  description = "DNS hostname of the ALB HTTPS origin."
  type        = string
}

variable "projectname" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}