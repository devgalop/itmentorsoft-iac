

resource "aws_elasticache_subnet_group" "sbngr_valkey" {
  name       = "${terraform.workspace}-${var.project}-valkey-subnets"
  subnet_ids = var.subnet_ids
}

# ElastiCache replication group for the Valkey cache
resource "aws_elasticache_replication_group" "rg_valkey" {
  replication_group_id = "${terraform.workspace}-${var.project}-valkey"
  description          = "ITMentorSoft Valkey cache"

  engine         = "valkey"
  engine_version = var.engine_version
  node_type      = var.node_type

  num_cache_clusters = 1

  automatic_failover_enabled = false
  multi_az_enabled            = var.multi_az

  subnet_group_name  = aws_elasticache_subnet_group.sbngr_valkey.name
  security_group_ids = [var.security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  apply_immediately = false
  tags = var.tags
}