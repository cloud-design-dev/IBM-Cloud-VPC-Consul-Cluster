resource "ibm_is_security_group" "consul_security_group" {
  name           = "${var.name}-consul-sg"
  vpc            = var.vpc_id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "ping" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "bastion_ssh_in" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.bastion_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "consul_http" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.consul_cidr
  tcp {
    port_min = 8500
    port_max = 8500
  }
}

resource "ibm_is_security_group_rule" "consul_tcp_in" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.consul_cidr
  tcp {
    port_min = 8300
    port_max = 8302
  }
}

resource "ibm_is_security_group_rule" "consul_udp_in" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.consul_cidr
  udp {
    port_min = 8301
    port_max = 8302
  }
}

resource "ibm_is_security_group_rule" "consul_udp_dns_in" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.consul_cidr
  udp {
    port_min = 8600
    port_max = 8600
  }
}

resource "ibm_is_security_group_rule" "consul_tcp_dns_in" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "inbound"
  remote    = var.consul_cidr
  tcp {
    port_min = 8600
    port_max = 8600
  }
}

resource "ibm_is_security_group_rule" "allow_outbound" {
  group     = ibm_is_security_group.consul_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}