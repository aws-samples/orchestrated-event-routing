// ----------------================ NEPTUNE ================----------------
resource "aws_neptune_cluster" "data" {
  cluster_identifier                   = "graph-data"
  engine                               = "neptune"
  backup_retention_period              = 1
  skip_final_snapshot                  = true
  iam_database_authentication_enabled  = false
  apply_immediately                    = true
  vpc_security_group_ids               = [aws_security_group.database.id]
  neptune_subnet_group_name            = aws_neptune_subnet_group.neptune-subnets.name
  neptune_cluster_parameter_group_name = "default.neptune1.2"

  serverless_v2_scaling_configuration {}
}

resource "aws_neptune_subnet_group" "neptune-subnets" {
  name_prefix = "neptune-subnets-"
  subnet_ids  = var.vpc_subnets_private_ids
}

resource "aws_neptune_cluster_instance" "main" {
  identifier                   = "graph-data-1"
  count                        = 1
  cluster_identifier           = aws_neptune_cluster.data.id
  engine                       = "neptune"
  instance_class               = "db.serverless"
  apply_immediately            = true
  neptune_parameter_group_name = "default.neptune1.2"
}