variable "aws_region" {
  description = "AWS region where the infra will be deployed"
  type        = string
}

variable "projectname" {
  description = "Short name for the project and the resource tags"
  type        = string
}

variable "environment" {
  description = "website staging"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance size for WordPress"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of WordPress Instances"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of WordPress Instances"
  type        = number
}

variable "subnet_ids" {
    description = "Subnets IDs for EC2."
    type = list(string)
    
}

variable "security_group_id" {
    description = "Security group for app"
    type = string
}

variable "target_group_arn" {
    description = "ALB target group for health check and traffic."
    type = string
}

variable "db_address" {
    description = "RDS endpoint address"
    type = string
}

variable "db_name" {
    description = "RDS name"
    type = string
}

variable "master_secret_arn" {
    description = "Master crendentials for the RDS."
    type = string
}

variable "efs_id" {
    description = "EFS file system id"
    type = string
}