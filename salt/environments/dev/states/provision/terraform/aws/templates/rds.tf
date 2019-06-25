module "{{ configs.rds.name }}-rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "{{ configs.rds.name }}-postgres"

  engine            = "postgres"
  engine_version    = "9.6.11"
  instance_class    = "{{ configs.rds.instance_size }}"
  allocated_storage = {{ configs.rds.size_gb }}
  storage_encrypted = false

  name = "{{ configs.rds.name }}"
  username = "{{ configs.rds.username }}"
  password = "{{ configs.rds.password }}"
  port     = "5432"

  vpc_security_group_ids = {{ configs.rds.security_groups_ids }}

  publicly_accessible = "true"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "{{ configs.rds.client_id }}"
    Environment = "dev"
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = {{ configs.rds.subnet_ids }}

  # DB parameter group
  family = "postgres9.6"

  # DB option group
  major_engine_version = "9.6"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "{{ configs.rds.name }}"

  # Database Deletion Protection
  deletion_protection = false
}
