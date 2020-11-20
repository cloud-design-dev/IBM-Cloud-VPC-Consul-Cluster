resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "${local.name}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, ["region:${var.region}", "project:${var.project_name}", "terraform:workspace:${terraform.workspace}"])
}

locals {
  name = "${var.project_name}-${terraform.workspace}"
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

resource ibm_is_network_acl consul_network_acl {
  name           = "${local.name}-consul-acl"
  vpc            = module.vpc.id
  resource_group = data.ibm_resource_group.project_group.id

  rules {
    name        = "egress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "ingress"
    action      = "allow"
    source      = module.edge_subnet.ipv4_cidr_block
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
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
  network_acl    = ibm_is_network_acl.consul_network_acl.id
  address_count  = "128"
  resource_group = var.resource_group
  public_gateway = module.public_gateway.id
}

module bastion {
  source            = "git::https://github.com/cloud-design-dev/ibm-vpc-instance-module.git"
  name              = "${local.name}-bastion"
  zone              = data.ibm_is_zones.mzr.zones[0]
  ssh_key           = ibm_is_ssh_key.generated_key.id
  vpc_id            = module.vpc.id
  subnet_id         = module.edge_subnet.id
  security_group_id = module.vpc.default_security_group
  resource_group    = var.resource_group
  image_name        = "ibm-ubuntu-20-04-minimal-amd64-2"
  tags              = concat(var.tags, ["bastion"])
}


resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.name}-bastion-public-ip"
  target         = module.bastion.primary_network_interface
  resource_group = data.ibm_resource_group.project_group.id
}

# module ansible {
#   source          = "./ansible"
#   instances       = ibm_is_instance.consul[*]
#   bastion_ip      = ibm_is_floating_ip.bastion.address
#   region          = var.region
#   encrypt_key     = var.encrypt_key
#   acl_token       = var.acl_token
#   private_key_pem = tls_private_key.ssh.private_key_pem
# }

