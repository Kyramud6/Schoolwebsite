variable "projectname" {
    description = "Project name"
    type = stirng
}

variable "environment" {
    description = "Deployment environment"
    type = string
}

variable "subnet_ids" {
    description = "Security groups access to the MySQL"
    type = string
}

variable "db_ver" {
    description = "Database's Engine Version"
    type = string
}

variable "db_instance" {
    description = "Database instance class"
    type = string
}

variable "db_name" {
    description = "RDS name."
    type = stirng
}

variable "db_username" {
    description = "Database master name, password"
    type = string
}

variable "security_group_id" {
    description = "Security group to access to SQL from app"
    type = string
}


variable "az_zone_db" {
    description = "Whether to deploy AZ."
    type = bool
}


