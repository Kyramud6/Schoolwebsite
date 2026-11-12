provider "aws" {
    region = var.region
}

default_tags {
    tags = {
        Project = var.projectname
        Environment = var.environment
    }
}