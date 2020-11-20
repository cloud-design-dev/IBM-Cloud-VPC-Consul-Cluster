# output bastion_public_ip {
#   value = ibm_is_floating_ip.bastion.address
# }

# # output vpc_subnets {
# #   value = ibm_is_vpc.vpc.subnets
# # }

# output bastion {
#   value = ibm_is_instance.bastion
# }

# output consul {
#   value = ibm_is_instance.consul[*]
# }

# output consul_names {
#   value = ibm_is_instance.consul[*].name
# }

# output consul_ips {
#   value = ibm_is_instance.consul[*].primary_network_interface[0].primary_ipv4_address
# }