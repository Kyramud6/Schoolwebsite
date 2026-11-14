variable "aws_region" {
  description = "AWS region where the infra will be deployed"
  type        = string
  default     = "ap-southeast-1"
}

variable "projectname" {
  description = "Short name for the project and the resource tags"
  type        = string
  default     = "yakin-bisa-lolo"
}

variable "environment" {
  description = "website staging"
  type        = string
  default     = "env"

  validation {
    condition     = contains(["env", "staging", "prod"], var.environment)
    error_message = "Environment must be only in env, staging or prod only."
  }
}


variable "vpc_dir" {
  description = "IPv4 range for the project"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Database for school website"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "admin for the database instance."
  type        = string
  default     = "wpadmin"
}

variable "db_instance" {
  description = "Instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "az_zone_db" {
  description = "let the db decide use a standby instance or another avaialble zone."
  type        = bool
  default     = false
}

variable "db_ver" {
  description = "MySQL version to be deploy"
  type        = string
  default     = "8.0"
}


variable "ec2_instance_type" {
  description = "EC2 instance size for WordPress"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of WordPress Instances"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of WordPress Instances"
  type        = number
  default     = 4
}