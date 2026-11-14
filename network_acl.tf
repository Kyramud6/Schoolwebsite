locals {
    network_acl_rule = {
        public_ingress = concat (
            [{key = "cloudfront_http", rule_number = 100, cidr = "0.0.0.0/0", from_port = 80, to_port = 80}],
            [for index, cidr in local.network_subnets.app : {
                key = "app_ephemeral_${index}"
                rule_number = 110 + index
                cidr = cidr
                from_port = 1024
                to_port = 6553
            }]
        )

        public_egress = concat(
            [for index, cidr in local.network_subnets.app : {
                key = "alb_to_app_http_${index}
                rule_number = 100 + index
                cidr = cidr
                from_port = 80
                to_port = 80
            }],
            [{key = "client_ephemeral",rule_number = 120, cidr = "0.0.0.0/0", from_port = 1024, to_port = 6553 }]

        )

        app_ingress = concat(
            [for index, cidr in local.network_subnets.public : {
                key = "alb_public_${index}"
                rule_number = 110 + index
                cidr = cidr
                from_port = 80
                to_port = 80
            }],
            [for index, cidr in local.network_subnets.public : {
                key = "alb_ephemeral_${index}"
                rule_number = 110 + index
                cidr = cidr
                from_port = 1024
                to_port = 6553
            }],
            [for index, cidr in local.network_subnets.data : {
                key="database_ephemeral_${index}"
                rule_number = 120 + index
                cidr = cidr
                from_port = 1024
                to_port = 6553
            }],
            [for index, cidr in local.network_subnets.app : {
                key = "efs_nfs_$(index)"
                rule_number = 130 + index
                cidr = cidr
                from_port = 2045
                to_port = 2045
            }],
            [{key = "external_ephemeral",rule_number = 140, cidr = "0.0.0.0/0", from_port = 1024, to_port = 6553}]
        )

        app_egress = concat (
            [for index, cidr in local.network_subnets.data {
                key = "mysql_${index}"
                rule_number = 100 + index
                cidr = cidr
                from_port = 3306
                to_port = 3306
            }],
            [
                {key = "http", rule_number = 110, cidr = "0.0.0.0/0", from_port = 80, to_port = 80 },
                {key = "https", rule_number = 120, cidr = "0.0.0.0/0", from_port = 443, to_port = 443 },
                {key = "external_ephemeral", rule_number = 130, cidr = "0.0.0.0/0", from_port = 1024, to_port = 6553 }
            ],
            [for index, cidr in local.network_subnets.app : {
                key = "efs_nfs_${index}"
                rule_number = 140 + index
                cidr = cidr
                from_port = 2045
                to_port = 2045
            }]
        )

        data_ingress = [for index, cidr in local.network_subnets.app : {
            key = "mysql_from_app_${index}
            rule_number = 100 + index
            cidr = cidr
            from_port = 3306
            to_port = 3306
        }]

        data_egress = [for index, cidr in local.network_subnets.app : {
            key = "mysql_response_to_app_${index}"
            rule_number = 100 + index
            cidr = cidr
            from_port = 1024
            to_port = 6553
        }]
    }
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
    for_each = { for rule in local.network_subnets.public_ingress : rule.key => rule }

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
    for_each = { for rule in local.network_subnets.public_egress : rule.key => rule }

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

    network_acl_id = aws_network_acl.app.id
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

    network_acl_id = aws_network_acl.app.id
    rule_number = each.value.rule_number
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = each.value.cidr
    from_port = each.value.from_port
    to_port = each.value.to_port
}