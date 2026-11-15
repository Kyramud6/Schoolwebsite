module "network" {
    source = "./modules/network"

    vpc_dir = var.vpc_dir
    projectname = var.projectname
    environment = var.environment
}

module "policies" {
    source = "./modules/policies"

    vpc_id = module.network.vpc_id
    projectname = var.projectname
    environment = var.environment
    depends_on = [module.network]
}

module "database" {
    source = "./modules/database"

    subnet_ids = module.network.data_subnet_ids
    security_group_id = module.policies.database_security_group_id
    projectname = var.projectname
    environment = var.environment
    db_name = var.db_name
    db_username = var.db_username
    db_instance = var.db_instance
    az_zone_db = var.az_zone_db
    db_ver = var.db_ver

    depends_on = [module.network, module.policies]

}

module "storage" {
    source = "./modules/storage"

    subnet_ids = module.network.app_subnet_ids
    security_group_id = module.policies.efs_security_group_id
    projectname      = var.projectname
    environment       = var.environment

    depends_on = [module.network, module.policies]
}

module "loadbalancer" {
    source = "./modules/loadbalancer"

    public_subnet_ids = module.network.public_subnet_ids
    security_group_id = module.policies.alb_security_group_id
    vpc_id            = module.network.vpc_id
    projectname      = var.projectname
    environment       = var.environment

    depends_on = [module.network, module.policies]
}

module "compute" {
    source = "./modules/compute"

    projectname      = var.projectname
    environment       = var.environment
    aws_region = var.region
    ec2_instance_type = var.ec2_instance_type
    asg_min_size = var.asg_min_size
    asg_max_size = var.asg_max_size
    subnet_ids = module.network.app_subnet_ids
    security_group_id = module.policies.app_security_group_id
    target_group_arn   = module.loadbalancer.target_group_arn
    db_address = module.database.database_address
    db_name = module.database.database_name
    master_secret_arn = module.database.master_secret_arn
    efs_id = module.storage.file_system_id

    depends_on = [module.network, module.policies, module.database, module.storage, module.loadbalancer]
}

module "cloudfront" {
    source = "./modules/cloudfront"

    lb_dns_name = module.loadbalancer.lb_dns_name
    projectname = var.projectname
    environment  = var.environment

    depends_on = [module.loadbalancer]
}

