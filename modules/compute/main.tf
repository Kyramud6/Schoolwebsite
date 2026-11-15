data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

}

resource "aws_iam_role" "ec2" {
  name = "${var.projectname}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_secretsmanager_secret" "wordpress_db_app" {
  name                    = "${var.projectname}/${var.environment}/wordpress-db-app"
  description             = "Least-privilege database credentials used by WordPress"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}

resource "aws_iam_role_policy" "wordpress_secret" {
  name = "${var.projectname}-${var.environment}-wordpress-secrets"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.master_secret_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"]
        Resource = [aws_secretsmanager_secret.wordpress_db_app.arn]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.projectname}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_launch_template" "wordpress" {
  name_prefix   = "${var.projectname}-${var.environment}-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [var.security_group_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/wordpress_user.sh.tftpl", {
    app_secret_arn    = aws_secretsmanager_secret.wordpress_db_app.arn
    aws_region        = var.aws_region
    db_address        = var.db_address
    db_name           = var.db_name
    efs_id            = var.efs_id
    master_secret_arn = var.master_secret_arn
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.projectname}-${var.environment}-wordpress"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.projectname}-${var.environment}-wordpress-root"
    }
  }
}

resource "aws_autoscaling_group" "wordpress" {
  name                      = "${var.projectname}-${var.environment}-wordpress"
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_min_size
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 900

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.projectname}-${var.environment}-wordpress"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.projectname}-${var.environment}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 1000
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.projectname}-${var.environment}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 1000
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.projectname}-${var.environment}-cpu-high"
  alarm_description   = "Scale out after CPU exceed 80% for 30 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 6
  period              = 300
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.projectname}-${var.environment}-cpu-low"
  alarm_description   = "Scale in after CPU stays below 40% for 30 minutes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 6
  period              = 300
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  threshold           = 40
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}

