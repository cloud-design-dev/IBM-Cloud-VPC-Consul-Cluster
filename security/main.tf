resource "ibm_is_security_group" "consul_security_group" {
  name           = "${var.name}-consul-sg"
  vpc            = var.vpc_id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "ssh_from_bastion" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.bastion_security_group
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "additional_all_rules" {
  for_each = {
    for rule in var.security_group_rules : rule.name => rule if lookup(rule, "tcp", null) == null && lookup(rule, "udp", null) == null && lookup(rule, "icmp", null) == null
  }
  group      = ibm_is_security_group.consul_security_group.id
  direction  = each.value.direction
  remote     = each.value.remote
  ip_version = lookup(each.value, "ip_version", null)
}

resource "ibm_is_security_group_rule" "additional_tcp_rules" {
  for_each = {
    for rule in var.security_group_rules : rule.name => rule if lookup(rule, "tcp", null) != null
  }
  group      = ibm_is_security_group.consul_security_group.id
  direction  = each.value.direction
  remote     = each.value.remote
  ip_version = lookup(each.value, "ip_version", null)

  tcp {
    port_min = each.value.tcp.port_min
    port_max = each.value.tcp.port_max
  }
}

resource "ibm_is_security_group_rule" "additional_udp_rules" {
  for_each = {
    for rule in var.security_group_rules : rule.name => rule if lookup(rule, "udp", null) != null
  }
  group      = ibm_is_security_group.consul_security_group.id
  direction  = each.value.direction
  remote     = each.value.remote
  ip_version = lookup(each.value, "ip_version", null)

  udp {
    port_min = each.value.udp.port_min
    port_max = each.value.udp.port_max
  }
}

resource "ibm_is_security_group_rule" "additional_icmp_rules" {
  for_each = {
    for rule in var.security_group_rules : rule.name => rule if lookup(rule, "icmp", null) != null
  }
  group      = ibm_is_security_group.consul_security_group.id
  direction  = each.value.direction
  remote     = each.value.remote
  ip_version = lookup(each.value, "ip_version", null)

  icmp {
    type = each.value.icmp.type
    code = lookup(each.value.icmp, "code", null) == null ? null : each.value.icmp.code
  }
}
