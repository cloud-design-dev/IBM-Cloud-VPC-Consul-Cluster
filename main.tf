resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "${local.name}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, [local.name, "terraform:workspace:${terraform.workspace}"])
}

locals {
  ssh_key_ids = var.ssh_key != "" ? [data.ibm_is_ssh_key.key.id, ibm_is_ssh_key.generated_key.id] : [ibm_is_ssh_key.generated_key.id]
  name        = "${var.project_name}-${terraform.workspace}"
}

resource ibm_is_vpc vpc {
  name           = "${local.name}-vpc"
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, ["vpc", var.region, var.project_name, "terraform:workspace:${terraform.workspace}"])
}


resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.name}-bastion-floating-ip"
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.project_group.id
}

module ansible {
  source          = "./ansible"
  instances       = ibm_is_instance.consul[*]
  bastion_ip      = ibm_is_floating_ip.bastion.address
  region          = var.region
  encrypt_key     = var.encrypt_key
  private_key_pem = tls_private_key.ssh.private_key_pem
  # instances = module.instance.instances
  # subnets = ibm_is_instance.consul[*].primary_network_interface[0].primary_ipv4_address
  # private_key_pem = tls_private_key.ssh.private_key_pem
}

