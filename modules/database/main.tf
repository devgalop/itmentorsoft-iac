# Create an IAM role and policy for the RDS scheduler
resource "aws_iam_role" "rds_scheduler" {
  name = "${terraform.workspace}-rds-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "scheduler.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create an IAM role policy for the RDS scheduler
resource "aws_iam_role_policy" "rds_scheduler" {

  name = "${terraform.workspace}-rds-scheduler-policy"

  role = aws_iam_role.rds_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]

        Resource = aws_db_instance.db_instance.arn
      }
    ]
  })
}

# Create a scheduler to start the RDS instance
resource "aws_scheduler_schedule" "rds_start" {

  name = "${terraform.workspace}-rds-start"

  schedule_expression = var.db_scheduler_start_time

  schedule_expression_timezone = "America/Bogota"

  flexible_time_window {
    mode = "OFF"
  }

  target {

    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.rds_scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = aws_db_instance.db_instance.identifier
    })
  }
}

# Create a scheduler to stop the RDS instance
resource "aws_scheduler_schedule" "rds_stop" {

  name = "${terraform.workspace}-rds-stop"

  schedule_expression = var.db_scheduler_stop_time

  schedule_expression_timezone = "America/Bogota"

  flexible_time_window {
    mode = "OFF"
  }

  target {

    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.rds_scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = aws_db_instance.db_instance.identifier
    })
  }
}


# Create a DB subnet group for the RDS instance
resource "aws_db_subnet_group" "sbn_databases" {
  name       = "${terraform.workspace}-rds-${var.project}-subnets"
  subnet_ids = var.subnet_ids
}

# Create the RDS instance
resource "aws_db_instance" "db_instance" {
  identifier = "${terraform.workspace}-rds-${var.project}-itmentorsoft"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = 5432

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.sbn_databases.name
  vpc_security_group_ids = [var.security_group_id]

  backup_retention_period = 0
  backup_window            = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  deletion_protection     = false
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = var.tags
}


output "db_address" { value = aws_db_instance.db_instance.address }
output "db_port" { value = aws_db_instance.db_instance.port }
    