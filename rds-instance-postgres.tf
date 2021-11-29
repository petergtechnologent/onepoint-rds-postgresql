# This template is designed for deploying an RDS PostgreSQL instance from the Morpheus UI. 
data "aws_vpc" "vpc_cidr" {
  id = var.vpc
}

locals {
  rds_postgres_power_schedule = "<%=customOptions.ot_power_schedule%>" != "null" ? "<%=customOptions.ot_power_schedule%>" : var.power_schedule
}

resource "aws_security_group" "postgres" {
  name              = format("%s-postgres-sg", "<%=instance.name%>")
  vpc_id            = var.vpc
  tags = {
    Name = "<%=instance.name%>"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = "5432"
  to_port           = "5432"
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc_cidr.cidr_block]
  security_group_id = aws_security_group.postgres.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.postgres.id
}

module "db" {

  source = "terraform-aws-modules/rds/aws"
  version = "~> 3.4" 
  identifier = "<%=instance.name%>"
  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "11.10"
  family               = "postgres11" # DB parameter group
  major_engine_version = "11"         # DB option group
  instance_class       = "<%=customOptions.ot_rds_instance_type%>"
  allocated_storage = 20
  max_allocated_storage = 100
  storage_encrypted     = false
  #kms_key_id = "arnfromcloudprofile"

  multi_az               = true
  subnet_ids             = local.subnets
  vpc_security_group_ids = [aws_security_group.postgres.id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  #performance_insights_enabled          = true
  #performance_insights_retention_period = 7
  #monitoring_interval                   = 60
  #create_monitoring_role                = true
  #monitoring_role_name                  = "<%=instance.name%>-monitoring-role"
  #monitoring_role_description           = "Monitoring role for RDS instance "

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"

  name                   = "<%=instance.name%>"
  username               = "<%=customOptions.ot_username%>"
  password               = "<%=customOptions.ot_password%>"
  #create_random_password = true
  #random_password_length = 12
  port                   = 5432

  tags = {
    Name = "<%=instance.name%>"
    PowerSchedule = local.rds_postgres_power_schedule
  }
  
}