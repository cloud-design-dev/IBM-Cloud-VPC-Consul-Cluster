output bastion_public_ip {
  value = ibm_is_floating_ip.bastion.address
}

output bastion_instance_ip {
  value = module.bastion.instance.primary_network_interface[0].primary_ipv4_address
}

output consul_instance_ip {
  value = module.consul[*].instance.primary_network_interface[0].primary_ipv4_address
}

output consul_names {
  value = module.consul[*].instance.name
}


