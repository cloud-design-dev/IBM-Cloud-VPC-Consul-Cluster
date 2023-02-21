output "bastion_public_ip" {
  value = ibm_is_floating_ip.bastion.address
}

output "packer_image_info" {
  value = packer_image.hashistack
}

output "packer_manifest" {
  depends_on = [
    data.local_file.packer_manifest
  ]
  value = data.local_file.packer_manifest.content
}

#output "consul_instance_ips" {
#  value = ibm_is_instance.cluster[*].primary_network_interface[0].primary_ipv4_address
#}

# output "consul_instance_names" {
#   value = module.consul_cluster[*].instance.name
# }


