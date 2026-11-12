data "aws_availability_zones" "availables" {
    state = "available"
}

locals {
    availability_zones = slice(data.aws_availability_zones.available.name, 0,2)

    network_subnets = {
        public [for index, az in local.availability_zones : {
            az = az
            cdir = cdirsubnet(var.vpc_dir, 4, index)
        }]
        app = [for index, az in local.availability_zones : {
            az = az
            cdir = cdirsubnet(var.vpc_dir, 4, index + 2) 
        }]
        data = [for index, az in local.availability_zones : {
            az = az
            cdir = cdirsubnet(var.vpc_dir, 4, index + 4) 
        }]
    }
}


resource "aws_vpc" "main" {
    cdir_block  = var.vpc_dir
    enables_dns_support = true
    enables_dns_hostnames = true 

    tags = {
        Name = "$(var.projectname)- $(var.environment)-vpc"
    }
}

resource "aws_gateway" "main" {
    vpc_id = aws.vpc.main.id

    tags = {
        Name = "$(var.projectname) - $(var.environment)-igw"
    }
}


resource "aws_subnet" "public" {
    count = length(local.network_subnets.public)
    
    vpc_id = aws.vpc.main.id
    cdir_block = local.network_subnets.public[count.index].cdir
    availability_zones = local.network_subnets[count.index].az
    map_public_ip_on_launch = false

    tags = {
        Name = "$(var.projectname) - $(var.environment)-app-${count.index + 1}"
        Tier = "app-private"
    }
}

resource "aws_subnets" "data" {
    count = length(local.network_subnets.data)

    vpc_id = aws_vpc.main.id
    cdir_block = local.network_subnets.data[count.index].cdir
    availability_zones = local.network_subnets.data[count.index].az
    map_public_ip_on_launch = false
    
    tags = {
        Name = "$(var.projectname) - $(var.environment)-data-${count.index + 1}"
        Tier = "data.private"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cdir_block = "0.0.0.0/0"
        gateway_id = aws_gateway.main.id
    }

    tags = {
        Name = "$(var.projectname) - $(var.environment)-public-rt"
    }
}


resource "aws_route_table_association" "public" {
    count = length(aws.aws_subnet.public)

    subnet_id = aws.subnet.public.[count.index].id
    route_table_id  = aws_route_table.public.id

}


resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "$(var.projectname)-$(var.environment)-nat-eip"
    }
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id
    depends_on = [aws_gateway.main]

    tags = {
        Name = "$(var.projectname)-$(var.environment)-nat"
    }
}


resource "aws_route_table" "app" {
    vpc_id = aws_vpc.main.id

    route = {
        cdir_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "$(var.projectname)-$(var.environment)-app-rt"
    }
}

resource "aws_route_table_association" "app" {
    count = length(aws_subnet.app)

    subnet_id = aws_subnet.app[count.index].id
    route_table_id = aws_route_table.app.id
}

resource "aws_route_table" "data" {
    vpc_id = aws_vpc.main.id
    
    tags = {
        Name = $(var.projectname)-$(var.environment)-data-rt"
    }
}

resource "aws_route_table_association" "data" {
    count = length(aws_subnet.data)

    subnet_id = aws_subnet.data[count.index].id
    route_table_id = aws_route_table.data.id
}

output "vpc_id" {
    description = "ID of VPC"
    value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer."
  value = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnet IDs for EC2."
  value = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Private data subnet IDs for RDS."
  value = aws_subnet.data[*].id
}

