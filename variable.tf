variable "vpc_dir" {
    description = "Ipv4 Range for VPC."
    type = string
    default = "10.0.0.0/16"
}

variable "projectname" { 
    description = "Project name"
    type = string
}

variable "environment" {
    description = "deployment environment"
    type = string
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_username" {
  type    = string
  default = "wpadmin"
}

variable "db_instance" {
  type    = string
  default = "db.t3.micro"
}

variable "az_zone_db" {
  type    = bool
  default = false
}

variable "db_ver" {
  type    = string
  default = "8.0"
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "region" {
    type = string
    default = "ap-southeast-1"
}

variable "domain_name" {
  description = "public domain and alb origin hostname"
  type = string
  default = "yakinbisalolos.click"
}