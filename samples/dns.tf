# resource "ibm_resource_instance" "project_instance" {
#   name              = "${local.name}-dns-instance"
#   resource_group_id = data.ibm_resource_group.project_group.id
#   location          = "global"
#   service           = "dns-svcs"
#   plan              = "standard-dns"
# }

# resource "ibm_dns_zone" "project_zone" {
#   name        = "${var.region}.consul"
#   instance_id = ibm_resource_instance.project_instance.guid
#   description = "Consul cluster testing"
#   label       = "testlabel-updated"
# }

# resource "ibm_dns_permitted_network" "project_permitted_network" {
#   instance_id = ibm_resource_instance.project_instance.guid
#   zone_id     = ibm_dns_zone.project_zone.zone_id
#   vpc_crn     = module.vpc.crn
# }

# resource "ibm_dns_resource_record" "bastion_a_record" {
#   instance_id = ibm_resource_instance.project_instance.guid
#   zone_id     = ibm_dns_zone.project_zone.zone_id
#   type        = "A"
#   name        = "${local.name}-bastion"
#   rdata       = ibm_is_instance.bastion.primary_network_interface[0].primary_ipv4_address
#   ttl         = 3600
# }

# resource "ibm_dns_resource_record" "consul_a_record" {
#   count       = length(data.ibm_is_zones.mzr.zones)
#   instance_id = ibm_resource_instance.project_instance.guid
#   zone_id     = ibm_dns_zone.project_zone.zone_id
#   type        = "A"
#   name        = "${local.name}-consul-instance-${count.index + 1}"
#   rdata       = ibm_is_instance.consul[count.index].primary_network_interface[0].primary_ipv4_address
#   ttl         = 3600
# }