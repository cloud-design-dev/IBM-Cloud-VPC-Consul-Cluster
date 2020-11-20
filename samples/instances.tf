# resource ibm_is_instance bastion {
#   name           = "${local.name}-bastion"
#   vpc            = module.vpc.id
#   zone           = data.ibm_is_zones.mzr.zones[0]
#   resource_group = data.ibm_resource_group.project_group.id
#   profile        = var.profile
#   image          = data.ibm_is_image.image.id
#   keys           = local.ssh_key_ids
#   user_data      = file("${path.module}/install.yml")

#   primary_network_interface {
#     subnet          = ibm_is_subnet.subnet[0].id
#     security_groups = [module.vpc.default_security_group]
#   }

#   boot_volume {
#     name = "${local.name}-bastion-boot"
#   }

#   tags = concat(var.tags, ["bastion", var.region, "terraform:workspace:${terraform.workspace}", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
# }

# resource ibm_is_instance consul {
#   count          = length(data.ibm_is_zones.mzr.zones)
#   name           = "${local.name}-consul-instance-${count.index + 1}"
#   vpc            = module.vpc.id
#   zone           = data.ibm_is_zones.mzr.zones[count.index]
#   resource_group = data.ibm_resource_group.project_group.id
#   profile        = var.profile
#   image          = data.ibm_is_image.image.id
#   keys           = local.ssh_key_ids
#   user_data      = templatefile("${path.module}/consul-init.sh", { region = var.region, project_name = local.name, encrypt_key = var.encrypt_key })

#   primary_network_interface {
#     subnet          = ibm_is_subnet.subnet[count.index].id
#     security_groups = [module.vpc.default_security_group]
#   }

#   boot_volume {
#     name = "${local.name}-instance-${count.index + 1}-boot"
#   }

#   tags = concat(var.tags, ["consul", var.region, "terraform:workspace:${terraform.workspace}", "zone:${data.ibm_is_zones.mzr.zones[count.index]}"])
# }