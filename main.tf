locals {
  name           = var.name != "" ? var.name : "hashivpc"
  ssh_key_ids    = var.ssh_key != "" ? [data.ibm_is_ssh_key.deploymentKey[0].id, ibm_is_ssh_key.generated_key.id] : [ibm_is_ssh_key.generated_key.id]
  resource_group = var.resource_group != "" ? var.resource_group : "CDE"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  name           = "${local.name}-${var.region}-sshkey"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["region:${var.region}", "vpc:${local.name}"])
}

module "vpc" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = local.name
  resource_group = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["vpc:${local.name}", "region:${var.region}"])
}

module "public_gateway" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${local.name}-pubgw"
  zone           = data.ibm_is_zones.mzr.zones[0]
  vpc            = module.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["vpc:${local.name}", "region:${var.region}"])
}

module "bastion-subnet" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${local.name}-bastion-subnet"
  resource_group = data.ibm_resource_group.group.id
  address_count  = "32"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[0]
  public_gateway = module.public_gateway.id
}

module "consul-subnet" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${local.name}-consul-subnet"
  resource_group = data.ibm_resource_group.group.id
  address_count  = "32"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[0]
  public_gateway = module.public_gateway.id
}

module "security" {
  source             = "./security"
  name               = local.name
  vpc_id             = module.vpc.id
  vpc_security_group = module.vpc.default_security_group
  consul_cidr        = module.consul-subnet.ipv4_cidr_block
  bastion_cidr       = module.bastion-subnet.ipv4_cidr_block
  resource_group     = data.ibm_resource_group.group.id
}

module "vpc-bastion" {
  depends_on        = [module.security]
  source            = "we-work-in-the-cloud/vpc-bastion/ibm"
  version           = "0.0.7"
  name              = "${local.name}-bastion"
  resource_group_id = data.ibm_resource_group.group.id
  vpc_id            = module.vpc.id
  subnet_id         = module.bastion-subnet.id
  ssh_key_ids       = local.ssh_key_ids
  allow_ssh_from    = var.allow_ssh_from
  create_public_ip  = var.create_public_ip
  init_script       = file("${path.module}/install.yml")
  tags              = concat(var.tags, ["region:${var.region}", "vpc:${local.name}", "bastion", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
}

module "consul_cluster" {
  count             = 3
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
  vpc_id            = module.vpc.id
  subnet_id         = module.consul-subnet.id
  ssh_keys          = local.ssh_key_ids
  resource_group    = data.ibm_resource_group.group.id
  name              = "${local.name}-consul${count.index + 1}"
  zone              = data.ibm_is_zones.mzr.zones[0]
  security_group_id = module.security.consul_security_group
  tags              = concat(var.tags, ["region:${var.region}", "vpc:${local.name}", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
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

 