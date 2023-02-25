output "bastion_public_ip" {
  value = ibm_is_floating_ip.bastion.address
}

# Used for troubleshooting. Currently, the default output returns null for the image ID. 
# Current workaround is to use the packer manifest file as a data source to get the image ID. 
# output "packer_image_info" {
#   value = packer_image.hashistack
# }

output "packer_image_id" {
  depends_on = [
    data.local_file.packer_manifest
  ]
  value = jsondecode(data.local_file.packer_manifest.content)["builds"][0]["artifact_id"]
}

output "consul_instance_ips" {
  value = ibm_is_instance.cluster[*].primary_network_interface[0].primary_ipv4_address
}



