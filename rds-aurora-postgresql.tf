# This template is designed for deploying an RDS PostgreSQL Aurora cluster from the Morpheus UI. 

data "aws_vpc" "vpc_cidr" {
  id = var.vpc
}

module "aurora" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 5.0"

  name                  = "<%=instance.name%>"
  engine                = "aurora-postgresql"
  engine_version        = "13.3"
  instance_type         = "<%=customOptions.ot_rds_oracle_instance_type%>" # this says oracle due to historical name of the optiontype in Morpheus.
  instance_type_replica = "<%=customOptions.ot_rds_oracle_instance_type%>" # this says oracle due to historical name of the optiontype in Morpheus.

  vpc_id                = var.vpc
  subnets               = local.subnets
  create_security_group = true
  allowed_cidr_blocks   = [data.aws_vpc.vpc_cidr.cidr_block]

  replica_count         = "<%=customOptions.ot_replica_count%>"

  username              = "<%=customOptions.ot_username%>"
  password              = "<%=customOptions.ot_password%>"

  apply_immediately   = true
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = ["postgresql"]


  tags = {
    Name = "<%=instance.name%>"
    }
}
