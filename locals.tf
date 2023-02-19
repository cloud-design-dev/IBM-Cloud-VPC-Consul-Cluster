locals {
  prefix      = var.project_prefix != "" ? var.project_prefix : "${random_string.prefix.0.result}-lab"
  ssh_key_ids = var.existing_ssh_key != "" ? [data.ibm_is_ssh_key.sshkey[0].id] : [module.ssh_key.0.ssh_key_id]

  tags = [
    "owner:${var.owner}",
    "provider:ibm",
    "region:${var.region}",
    "vpc:${local.prefix}-vpc",
    "tf_workspace:${terraform.workspace}"
  ]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }

  backend_acl_rules = [
    for r in var.backend_acl_rules : {
      name        = r.name
      action      = r.action
      source      = r.source
      destination = r.destination
      direction   = r.direction
      icmp        = lookup(r, "icmp", null)
      tcp         = lookup(r, "tcp", null)
      udp         = lookup(r, "udp", null)
    }
  ]

  backend_sg_rules = [
    for r in var.backend_sg_rules : {
      name       = r.name
      direction  = r.direction
      remote     = lookup(r, "remote", null)
      ip_version = lookup(r, "ip_version", null)
      icmp       = lookup(r, "icmp", null)
      tcp        = lookup(r, "tcp", null)
      udp        = lookup(r, "udp", null)
    }
  ]
}
