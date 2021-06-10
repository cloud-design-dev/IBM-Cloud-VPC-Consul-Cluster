output "bastion_public_ip" {
  value = module.vpc-bastion.bastion_public_ip
}

output "consul_instance_ip" {
  value = module.consul_cluster[*].instance.primary_network_interface[0].primary_ipv4_address
}

output "consul_instance_names" {
  value = module.consul_cluster[*].instance.name
}


