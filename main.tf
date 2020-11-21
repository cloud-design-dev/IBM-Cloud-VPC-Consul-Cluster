locals {
  name = "${terraform.workspace}-${formatdate("DD-MMM-YY-hh-mm", timestamp())}"
}

resource "random_string" "random" {
  length    = 24
  special   = false
  min_upper = 8
}

resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "sshkey-${local.name}-${var.region}"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, ["region:${var.region}", "project:${local.name}", "terraform:workspace:${terraform.workspace}"])
}

module vpc {
  source         = "./vpc"
  name           = local.name
  zone           = data.ibm_is_zones.mzr.zones[0]
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, ["region:${var.region}", "project:${local.name}", "terraform:workspace:${terraform.workspace}"])
  remote_ip      = var.remote_ip
}

module bastion {
  source            = "./instance"
  name              = "${local.name}-${data.ibm_is_zones.mzr.zones[0]}-bastion"
  zone              = data.ibm_is_zones.mzr.zones[0]
  ssh_key           = ibm_is_ssh_key.generated_key.id
  vpc_id            = module.vpc.vpc.id
  subnet_id         = module.vpc.bastion_subnet_id
  security_group_id = module.vpc.default_security_group
  resource_group    = data.ibm_resource_group.project_group.id
  tags              = concat(var.tags, ["region:${var.region}", "project:${local.name}", "bastion", "terraform:workspace:${terraform.workspace}"])
  password_hash     = sha512(random_string.random.result)
  public_key        = tls_private_key.ssh.public_key_openssh
}

module consul_security {
  source             = "./security"
  name               = local.name
  vpc_id            = module.vpc.vpc.id
  vpc_security_group = module.vpc.default_security_group
  consul_cidr        = module.vpc.consul_subnet_cidr
  resource_group    = data.ibm_resource_group.project_group.id
}

module consul {
  source            = "./instance"
  count             = 3
  name              = "${local.name}-${data.ibm_is_zones.mzr.zones[0]}-consul${count.index + 1}"
  zone              = data.ibm_is_zones.mzr.zones[0]
  ssh_key           = ibm_is_ssh_key.generated_key.id
  vpc_id            = module.vpc.vpc.id
  subnet_id         = module.vpc.consul_subnet_id
  security_group_id = module.security.consul_security_group
  resource_group    = data.ibm_resource_group.project_group.id
  tags              = concat(var.tags, ["region:${var.region}", "project:${local.name}", "consul", "terraform:workspace:${terraform.workspace}"])
  password_hash     = sha512(random_string.random.result)
  public_key        = tls_private_key.ssh.public_key_openssh
}

# module ansible {
#   source          = "./ansible"
#   instances       = module.consul[*].instance
#   bastion_ip      = ibm_is_floating_ip.bastion.address
#   region          = var.region
#   encrypt_key     = var.encrypt_key
#   private_key_pem = tls_private_key.ssh.private_key_pem
# }

resource "local_file" "ssh-key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/generated_key_rsa"
  file_permission = "0600"
}

 