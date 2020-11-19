resource "ibm_is_security_group_rule" "consul_server_http" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = cidrsubnet(ibm_is_subnet.subnet[0].ipv4_cidr_block, -6, 0)
  tcp {
    port_max = 8500
    port_min = 8500
  }
}

resource "ibm_is_security_group_rule" "out_all" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}


resource "ibm_is_security_group_rule" "consul_client_wan_tcp" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = cidrsubnet(ibm_is_subnet.subnet[0].ipv4_cidr_block, -6, 0)
  tcp {
    port_min = 8300
    port_max = 8302
  }
}


resource "ibm_is_security_group_rule" "ssh_in" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "rdp_in" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 3389
    port_max = 3389
  }
}

resource "ibm_is_security_group_rule" "vpc_wan_udp" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = cidrsubnet(ibm_is_subnet.subnet[0].ipv4_cidr_block, -6, 0)
  udp {
    port_min = 8301
    port_max = 8302
  }
}