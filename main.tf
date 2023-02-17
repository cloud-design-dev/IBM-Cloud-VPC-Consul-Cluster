resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
}

module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "ssh_key" {
  count             = var.existing_ssh_key != "" ? 0 : 1
  source            = "terraform-ibm-modules/vpc/ibm//modules/ssh-key"
  name              = "${local.prefix}-${var.region}-sshkey"
  resource_group_id = module.resource_group.resource_group_id
  public_key        = tls_private_key.ssh.0.public_key_openssh
  tags              = local.tags
}

module "vpc" {
  source                      = "terraform-ibm-modules/vpc/ibm//modules/vpc"
  version                     = "1.1.1"
  create_vpc                  = true
  vpc_name                    = "${local.prefix}-vpc"
  resource_group_id           = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  default_address_prefix      = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  vpc_tags                    = local.tags
  locations                   = [local.vpc_zones[0].zone]
  number_of_addresses         = "128"
  create_gateway              = true
  subnet_name                 = "${local.prefix}-frontend-subnet"
  public_gateway_name         = "${local.prefix}-pub-gw"
  gateway_tags                = local.tags
}

# module "security" {
#   source                 = "./security"
#   name                   = var.name
#   vpc_id                 = local.vpc.id
#   bastion_security_group = module.vpc-bastion.bastion_maintenance_group_id
#   resource_group         = local.resource_group
# }


# 
# module "vpc-bastion" {
#   depends_on        = [local.vpc]
#   source            = "we-work-in-the-cloud/vpc-bastion/ibm"
#   version           = "0.0.7"
#   name              = "${var.name}-bastion"
#   resource_group_id = local.resource_group
#   vpc_id            = local.vpc.id
#   subnet_id         = local.subnet_id
#   ssh_key_ids       = local.ssh_key_ids
#   allow_ssh_from    = var.allow_ssh_from
#   create_public_ip  = var.create_public_ip
#   init_script       = file("${path.module}/install.yml")
#   tags              = concat(var.tags, ["region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
# }

# module "consul_cluster" {
#   count           = 3
#   source          = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
#   vpc_id          = local.vpc.id
#   subnet_id       = local.subnet_id
#   ssh_keys        = local.ssh_key_ids
#   resource_group  = local.resource_group
#   name            = "${var.name}-consul${count.index + 1}"
#   zone            = data.ibm_is_zones.mzr.zones[0]
#   security_groups = module.security.consul_security_group
#   tags            = concat(var.tags, ["region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
#   user_data       = file("${path.module}/install.yml")
# }

# resource "ibm_is_security_group_network_interface_attachment" "under_maintenance" {
#   depends_on        = [module.consul_cluster]
#   count             = 3
#   network_interface = module.consul_cluster[count.index].instance.primary_network_interface.0.id
#   security_group    = module.vpc-bastion.bastion_maintenance_group_id
# }


# module "ansible" {
#   source          = "./ansible"
#   instances       = module.consul_cluster[*].instance
#   bastion_ip      = module.vpc-bastion.bastion_public_ip
#   region          = var.region
#   encrypt_key     = var.encrypt_key
#   private_key_pem = tls_private_key.ssh.private_key_pem
# }


