resource "ibm_is_vpc" "vpc" {
  name           = "${var.name}-vpc"
  resource_group = var.resource_group
  tags           = concat(var.tags, ["vpc"])
}

resource ibm_is_public_gateway gateway {
  name           = "${var.name}-${var.zone}-gateway"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  resource_group = var.resource_group
}

resource ibm_is_subnet bastion_subnet {
  name                     = "${var.name}-${var.zone}-bastion-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = var.address_count["bastion"]
  public_gateway           = ibm_is_public_gateway.gateway.id
  resource_group           = var.resource_group
}

resource ibm_is_subnet consul_subnet {
  name                     = "${var.name}-${var.zone}-consul-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = var.address_count[consul]
  public_gateway           = ibm_is_public_gateway.gateway.id
  resource_group           = var.resource_group
}

resource "ibm_is_security_group_rule" "inbound_ssh" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = var.remote_ip
  tcp {
    port_min = 22
    port_max = 22
  }
}