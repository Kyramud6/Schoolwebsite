variables "region" {
    description = "AWS region where the infra will be deployed"
    type = string
    default = "ap-southeast-1"
}

variables "projectname" {
    description = "Short name for the project and the resource tags"
    type = string
    default = "yakin-bisa-lolo"
}

variables "environment" {
    description = "website staging"
    type = string
    default = "env"

    validation {
        condition = contains(["env","staging","prod"], var.environment)
        error_message = "Environment must be only in env, staging or prod only."
    }
}


variables "vpc_dir" {
    description = "IPv4 range for the project"
    type = string
    default = "10.0.0.0/16
}

variable "db_name" {
    description = "Database for school website"
    type = string
    default = "wordpress"
}

variable "db_username" {
    description = "admin for the database instance."
    type = string
    default = "wpadmin"
}

variable "db_instance" {
    description = "Instance size"
    type = string
    default = "db.t3.mirco"
}

variable "az_zone_db" {
    description = "let the db decide use a standby instance or another avaialble zone."
    type = bool
    default = false
}

variable "db_ver" {
    description = "MySQL version to be deploy"
    type = string
    default = "8.0"
}