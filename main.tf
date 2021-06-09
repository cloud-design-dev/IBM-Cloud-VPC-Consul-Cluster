locals {
  name           = var.name != "" ? var.name : "hashivpc"
  ssh_key_ids    = var.ssh_key != "" ? [data.ibm_is_ssh_key.deploymentKey[0].id, ibm_is_ssh_key.generated_key.id] : [ibm_is_ssh_key.generated_key.id]
  resource_group = var.existing_resource_group != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
  vpc            = var.existing_vpc_name != "" ? data.ibm_is_vpc.vpc.0.id : module.vpc.0.id
  subnet_id      = var.existing_subnet_name != "" ? data.ibm_is_subnet.existing_subnet.0.id : module.subnet.0.id
}

resource "ibm_resource_group" "group" {
  count = var.existing_resource_group != "" ? 0 : 1
  name  = "${local.name}-group"
  tags  = concat(var.tags, ["vpc:${local.name}-vpc"])
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  name           = "${local.name}-${var.region}-sshkey"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = local.resource_group
  tags           = concat(var.tags, ["region:${var.region}", "vpc:${local.name}-vpc"])
}

module "vpc" {
  count          = var.existing_vpc_name != "" ? 0 : 1
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = "${local.name}-vpc"
  resource_group = local.resource_group
  tags           = concat(var.tags, ["vpc:${local.name}-vpc", "region:${var.region}"])
}

module "public_gateway" {
  count          = var.existing_subnet_name != "" ? 0 : 1
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${local.name}-pubgw"
  zone           = data.ibm_is_zones.mzr.zones[0]
  vpc            = local.vpc
  resource_group = local.resource_group
  tags           = concat(var.tags, ["vpc:${local.name}", "region:${var.region}"])
}

module "subnet" {
  count          = var.existing_subnet_name != "" ? 0 : 1
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${local.name}-subnet"
  resource_group = local.resource_group
  address_count  = "32"
  vpc            = local.vpc
  zone           = data.ibm_is_zones.mzr.zones.0
  public_gateway = module.public_gateway.0.id
}

module "security" {
  source                 = "./security"
  name                   = local.name
  vpc_id                 = local.vpc
  bastion_security_group = module.vpc-bastion.bastion_maintenance_group_id
  resource_group         = local.resource_group
}

module "vpc-bastion" {
  depends_on        = [module.security]
  source            = "we-work-in-the-cloud/vpc-bastion/ibm"
  version           = "0.0.7"
  name              = "${local.name}-bastion"
  resource_group_id = local.resource_group
  vpc_id            = local.vpc
  subnet_id         = local.subnet_id
  ssh_key_ids       = local.ssh_key_ids
  allow_ssh_from    = var.allow_ssh_from
  create_public_ip  = var.create_public_ip
  init_script       = file("${path.module}/install.yml")
  tags              = concat(var.tags, ["region:${var.region}", "vpc:${local.name}", "bastion", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
}

module "consul_cluster" {
  count             = 3
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
  vpc_id            = local.vpc
  subnet_id         = local.subnet_id
  ssh_keys          = local.ssh_key_ids
  resource_group    = local.resource_group
  name              = "${local.name}-consul${count.index + 1}"
  zone              = data.ibm_is_zones.mzr.zones[0]
  security_group_id = module.security.consul_security_group
  tags              = concat(var.tags, ["region:${var.region}", "vpc:${local.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
  user_data         = file("${path.module}/install.yml")
}

module "ansible" {
  source          = "./ansible"
  instances       = module.consul_cluster[*].instance
  bastion_ip      = module.vpc-bastion.bastion_public_ip
  region          = var.region
  encrypt_key     = var.encrypt_key
  private_key_pem = tls_private_key.ssh.private_key_pem
}

resource "local_file" "ssh-key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/generated_key_rsa"
  file_permission = "0600"
}


