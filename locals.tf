locals {
  prefix      = var.project_prefix != "" ? var.project_prefix : "${random_string.prefix.0.result}-lab"
  ssh_key_ids = var.existing_ssh_key != "" ? [data.ibm_is_ssh_key.sshkey[0].id] : [module.ssh_key.0.ssh_key_id]

  tags = [
    "owner:${var.owner}",
    "provider:ibm",
    "region:${var.region}",
    "vpc:${local.prefix}-vpc",
  ]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }

  #   frontend_rules = [
  #     for r in var.frontend_rules : {
  #       name       = r.name
  #       direction  = r.direction
  #       remote     = lookup(r, "remote", null)
  #       ip_version = lookup(r, "ip_version", null)
  #       icmp       = lookup(r, "icmp", null)
  #       tcp        = lookup(r, "tcp", null)
  #       udp        = lookup(r, "udp", null)
  #     }
  #   ]
}