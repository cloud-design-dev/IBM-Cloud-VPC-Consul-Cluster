output bastion_subnet_cidr {
  value = ibm_is_subnet.bastion_subnet.ipv4_cidr_block
}

output consul_subnet_cidr {
  value = ibm_is_subnet.consul_subnet.ipv4_cidr_block
}

output bastion_subnet_id {
  value = ibm_is_subnet.bastion_subnet.id
}

output consul_subnet_id {
  value = ibm_is_subnet.bastion_subnet.id
}

output vpc {
  value = ibm_is_vpc.vpc
}