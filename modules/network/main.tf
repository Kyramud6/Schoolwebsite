data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  network_subnets = {
    public = [for index, az in local.availability_zones : {
      az   = az
      cidr = cidrsubnet(var.vpc_dir, 4, index)
    }]

    app = [for index, az in local.availability_zones : {
      az   = az
      cidr = cidrsubnet(var.vpc_dir, 4, index + 2)
    }]

    data = [for index, az in local.availability_zones : {
      az   = az
      cidr = cidrsubnet(var.vpc_dir, 4, index + 4)
    }]
  }
  network_acl_rule = {
  public_ingress = concat(
    [
      { key = "cloudfront_http",  rule_number = 100, cidr = "0.0.0.0/0", from_port = 80,   to_port = 80 },
      { key = "cloudfront_https", rule_number = 101, cidr = "0.0.0.0/0", from_port = 443,  to_port = 443 }
    ],
    [
      for index, subnet in local.network_subnets.app : {
        key         = "app_ephemeral_${index}"
        rule_number = 110 + index
        cidr        = subnet.cidr
        from_port   = 1024
        to_port     = 65535
      }
    ],
    [
      { key = "nat_response", rule_number = 120, cidr = "0.0.0.0/0", from_port = 1024, to_port = 65535 }
    ]
  )
    public_egress = concat(
      [for index, cidr in local.network_subnets.app : {
        key = "lb_to_app_http_${index}"
        rule_number = 100 + index
        cidr = cidr.cidr
        from_port = 80
        to_port = 80
      }],
      [ { key = "client_response", rule_number = 110, cidr = "0.0.0.0/0", from_port = 1024, to_port = 65535 },
      { key = "nat_http", rule_number = 120, cidr = "0.0.0.0/0", from_port = 80, to_port = 80 },
      { key = "nat_https", rule_number = 121, cidr = "0.0.0.0/0", from_port = 443, to_port = 443 }]
      )

    app_ingress = concat(
      [for index, cidr in local.network_subnets.public : {
        key = "alb_public_${index}"
        rule_number = 100 + index
        cidr = cidr.cidr
        from_port = 80
        to_port = 80
      }],
      [for index, cidr in local.network_subnets.public : {
        key = "alb_ephemeral_${index}"
        rule_number = 110 + index
        cidr = cidr.cidr
        from_port = 1024
        to_port = 65535
      }],
      [{key = "internet_response", rule_number = 140, cidr = "0.0.0.0/0", from_port = 1024, to_port = 65535}]
      ,
      [for index, cidr in local.network_subnets.app : {
      key = "efs_nfs_${index}"
        rule_number = 130 + index
        cidr = cidr.cidr
        from_port = 2049
        to_port = 2049
      }]
      )

      app_egress = concat (
        [for index, cidr in local.network_subnets.data : {
          key = "mysql_${index}"
          rule_number = 100 + index
          cidr = cidr.cidr 
          from_port = 3306
          to_port = 3306
      }],
      [
        {key = "http", rule_number = 110, cidr = "0.0.0.0/0", from_port = 80, to_port = 80 },
        {key = "https", rule_number = 120, cidr = "0.0.0.0/0", from_port = 443, to_port = 443 }
      ],
      [for index, cidr in local.network_subnets.app : {
        key = "efs_nfs_${index}"
        rule_number = 130 + index
        cidr = cidr.cidr
        from_port = 2049
        to_port = 2049
      }]
      )

      data_ingress = [for index, cidr in local.network_subnets.app : {
        key = "mysql_from_app_${index}"
        rule_number = 100 + index
        cidr = cidr.cidr 
        from_port = 3306
        to_port = 3306
      }]

      data_egress = [for index, cidr in local.network_subnets.app : {
        key = "mysql_response_to_app_${index}"
        rule_number = 100 + index
        cidr = cidr.cidr
        from_port = 1024
        to_port = 65535
      }]
    }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_dir
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projectname}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projectname}-${var.environment}-igw"
  }
}


resource "aws_subnet" "public" {
  count = length(local.network_subnets.public)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.network_subnets.public[count.index].cidr
  availability_zone       = local.network_subnets.public[count.index].az
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.projectname} - ${var.environment}-app-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  count = length(local.network_subnets.app)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.network_subnets.app[count.index].cidr
  availability_zone       = local.network_subnets.app[count.index].az
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.projectname}-${var.environment}-app-${count.index + 1}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "data" {
  count = length(local.network_subnets.app)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.network_subnets.data[count.index].cidr
  availability_zone       = local.network_subnets.data[count.index].az
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.projectname}-${var.environment}-data-${count.index + 1}"
    Tier = "data-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.projectname}-${var.environment}-public-rt"
  }
}


resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

}


resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.projectname}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.projectname}-${var.environment}-nat"
  }
}


resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.projectname}-${var.environment}-app-rt"
  }
}

resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projectname}-${var.environment}-data-rt"
  }
}

resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data)

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

resource "aws_network_acl" "public" {
    vpc_id = aws_vpc.main.id
    subnet_ids = aws_subnet.public[*].id

    tags = {
        Name = "${var.projectname}-${var.environment}-public-alc"
        Tier = "public"  
    }
}

resource "aws_network_acl_rule" "public_ingress" {
    for_each = { for rule in local.network_acl_rule.public_ingress : rule.key => rule }

    network_acl_id = aws_network_acl.public.id
    rule_number = each.value.rule_number
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}

resource "aws_network_acl_rule" "public_egress" {
    for_each = { for rule in local.network_acl_rule.public_egress : rule.key => rule }

    network_acl_id = aws_network_acl.public.id
    rule_number = each.value.rule_number
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}

resource "aws_network_acl" "app" {
    vpc_id = aws_vpc.main.id
    subnet_ids = aws_subnet.app[*].id

    tags = {
        Name = "${var.projectname}-${var.environment}-app-acl"
        Tier = "app-private"
    }
}

resource "aws_network_acl_rule" "app_ingress" {
    for_each = { for rule in local.network_acl_rule.app_ingress : rule.key => rule}

    network_acl_id = aws_network_acl.app.id
    rule_number = each.value.rule_number
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}

resource "aws_network_acl_rule" "app_egress" {
    for_each = { for rule in local.network_acl_rule.app_egress : rule.key => rule}

    network_acl_id = aws_network_acl.app.id
    rule_number = each.value.rule_number
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}

resource "aws_network_acl" "data" {
    vpc_id = aws_vpc.main.id
    subnet_ids = aws_subnet.data[*].id

    tags ={
        Name = "${var.projectname}-${var.environment}-data-acl"
        Tier = "data-private"
    }
}

resource "aws_network_acl_rule" "data_ingress" {
    for_each = { for rule in local.network_acl_rule.data_ingress : rule.key => rule}

    network_acl_id = aws_network_acl.data.id
    rule_number = each.value.rule_number
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}

resource "aws_network_acl_rule" "data_egress" {
    for_each = { for rule in local.network_acl_rule.data_egress : rule.key => rule}

    network_acl_id = aws_network_acl.data.id
    rule_number = each.value.rule_number
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}