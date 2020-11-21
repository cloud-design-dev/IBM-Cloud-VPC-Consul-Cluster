resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "sshkey-${local.keyname}-${var.region}"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.project_group.id
  tags           = concat(var.tags, ["region:${var.region}", "project:${var.project_name}", "terraform:workspace:${terraform.workspace}"])
}


resource "ibm_is_security_group_rule" "out_all" {
  group     = module.vpc.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "ssh_in" {
  group     = module.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "rdp_in" {
  group     = module.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 3389
    port_max = 3389
  }
}