locals {
  name    = "${var.project_name}-${terraform.workspace}"
  keyname = formatdate("hh", timestamp())
}

module vpc {
  source         = "git::https://github.com/cloud-design-dev/ibm-vpc-module.git"
  name           = "${local.name}-vpc"
  resource_group = var.resource_group
  tags           = concat(var.tags, ["region:${var.region}", "project:${var.project_name}", "terraform:workspace:${terraform.workspace}"])
}

module public_gateway {
  source         = "git::https://github.com/cloud-design-dev/ibm-vpc-public-gateway-module.git"
  name           = local.name
  vpc_id         = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[0]
  resource_group = var.resource_group
}

module edge_subnet {
  source         = "git::https://github.com/cloud-design-dev/ibm-vpc-subnet-count-module.git"
  name           = "${local.name}-edge"
  address_count  = "8"
  resource_group = var.resource_group
  zone           = data.ibm_is_zones.mzr.zones[0]
  public_gateway = module.public_gateway.id
  vpc_id         = module.vpc.id
  network_acl    = module.vpc.default_network_acl
}

module consul_subnet {
  source         = "git::https://github.com/cloud-design-dev/ibm-vpc-subnet-count-module.git"
  name           = "${local.name}-consul"
  zone           = data.ibm_is_zones.mzr.zones[0]
  vpc_id         = module.vpc.id
  network_acl    = module.vpc.default_network_acl
  address_count  = "128"
  resource_group = var.resource_group
  public_gateway = module.public_gateway.id
}

module bastion {
  source            = "./instance"
  name              = "${local.name}-bastion"
  zone              = data.ibm_is_zones.mzr.zones[0]
  ssh_key           = var.ssh_key
  vpc_id            = module.vpc.id
  subnet_id         = module.edge_subnet.id
  security_group_id = module.vpc.default_security_group
  resource_group    = var.resource_group
  tags              = concat(var.tags, ["bastion"])
  user_data         = file("./instance/init.sh")
}


resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.name}-bastion-public-ip"
  target         = module.bastion.primary_network_interface_id
  resource_group = data.ibm_resource_group.project_group.id
}

module consul {
  source            = "./instance"
  count             = 3
  name              = "${local.name}-consul${count.index + 1}"
  zone              = data.ibm_is_zones.mzr.zones[0]
  ssh_key           = var.ssh_key
  vpc_id            = module.vpc.id
  subnet_id         = module.consul_subnet.id
  security_group_id = module.vpc.default_security_group
  resource_group    = var.resource_group
  tags              = concat(var.tags, ["consul"])
  user_data         = templatefile("./instance/consul-init.sh", { subnet_cidr = module.consul_subnet.ipv4_cidr_block, region = var.region, encrypt_key = var.encrypt_key })
}

module ansible {
  source          = "./ansible"
  instances       = module.consul[*].instance
  bastion_ip      = ibm_is_floating_ip.bastion.address
  region          = var.region
  encrypt_key     = var.encrypt_key
  private_key_pem = tls_private_key.ssh.private_key_pem
}

resource "local_file" "ssh-key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/generated_key_rsa"
  file_permission = "0600"
}

