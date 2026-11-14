provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.projectname
      Environment = var.environment
    }
  }
}

