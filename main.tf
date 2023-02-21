

resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  numeric = false
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

module "backend_network_acl" {
  source = "terraform-ibm-modules/vpc/ibm//modules/network-acl"

  name              = "${local.prefix}-backend-acl"
  vpc_id            = module.vpc.vpc_id[0]
  resource_group_id = module.resource_group.resource_group_id
  rules             = local.backend_acl_rules
  tags              = local.tags
}

module "backend_security_group" {
  source = "terraform-ibm-modules/vpc/ibm//modules/security-group"

  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = module.vpc.vpc_id[0]
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.backend_sg_rules
}

module "frontend_security_group" {
  source = "terraform-ibm-modules/vpc/ibm//modules/security-group"

  create_security_group = false
  security_group        = module.vpc.vpc_default_security_group[0]
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules = [
    {
      name       = "inbound-frontend-ssh"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 22
        port_max = 22
      }
      icmp = null
      udp  = null
    }
  ]
}

resource "ibm_is_instance" "bastion" {
  name                     = "${local.prefix}-bastion"
  vpc                      = module.vpc.vpc_id[0]
  image                    = data.ibm_is_image.base.id
  profile                  = var.instance_profile
  resource_group           = module.resource_group.resource_group_id
  metadata_service_enabled = var.metadata_service_enabled

  boot_volume {
    name = "${local.prefix}-boot-volume"
  }

  primary_network_interface {
    subnet            = module.vpc.subnet_ids[0]
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.vpc.vpc_default_security_group[0]]
  }

  user_data = file("${path.module}/install.yml")
  zone      = local.vpc_zones[0].zone
  keys      = local.ssh_key_ids
  tags      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-bastion-public-ip"
  resource_group = module.resource_group.resource_group_id
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

module "backend_subnet" {
  source = "terraform-ibm-modules/vpc/ibm//modules/subnet"

  name                       = "${local.prefix}-backend-subnet"
  vpc_id                     = module.vpc.vpc_id[0]
  resource_group_id          = module.resource_group.resource_group_id
  location                   = local.vpc_zones[0].zone
  number_of_addresses        = 64
  subnet_access_control_list = module.backend_network_acl.network_acl_id
  public_gateway             = module.vpc.public_gateway_ids[0]
}



resource "packer_image" "hashistack" {
  file = data.packer_files.base.file
  variables = {
    # Take out explicit API key and use the environment variable instead in packer file
    # ibmcloud_api_key  = var.ibmcloud_api_key
    resource_group_id = "${module.resource_group.resource_group_id}"
    subnet_id         = "${module.vpc.subnet_ids[0]}"
    region            = var.region
    template_name     = "${local.prefix}-base-image"
    base_image_id     = "${data.ibm_is_image.base.id}"
  }

  triggers = {
    packer_version = data.packer_version.version.version
    files_hash     = data.packer_files.base.files_hash
  }
}

resource "ibm_is_instance" "cluster" {
  depends_on               = [packer_image.hashistack]
  count                    = 3
  name                     = "${local.prefix}-instance-${count.index}"
  vpc                      = module.vpc.vpc_id[0]
  image                    = jsondecode(data.local_file.packer_manifest.content)["builds"][0]["artifact_id"]
  profile                  = var.instance_profile
  resource_group           = module.resource_group.resource_group_id
  metadata_service_enabled = var.metadata_service_enabled
  primary_network_interface {
    subnet            = module.backend_subnet.subnet_id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.backend_security_group.security_group_id[0]]
  }

  user_data = file("${path.module}/install.yml")
  zone      = local.vpc_zones[0].zone
  keys      = local.ssh_key_ids
  tags      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}


module "cos" {
  count                    = var.existing_cos_instance != "" ? 0 : 1
  depends_on               = [module.vpc]
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v5.3.1"
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  create_hmac_key          = (var.existing_cos_instance != "" ? false : true)
  create_cos_bucket        = false
  encryption_enabled       = false
  hmac_key_name            = (var.existing_cos_instance != "" ? null : "${local.prefix}-hmac-key")
  cos_instance_name        = (var.existing_cos_instance != "" ? null : "${local.prefix}-cos-instance")
  cos_tags                 = local.tags
  existing_cos_instance_id = (var.existing_cos_instance != "" ? local.cos_instance : null)
}

resource "ibm_iam_authorization_policy" "cos_flowlogs" {
  count                       = var.existing_cos_instance != "" ? 0 : 1
  depends_on                  = [module.cos]
  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = local.cos_guid
  roles                       = ["Writer", "Reader"]
}

module "backend_bucket" {
  depends_on               = [ibm_iam_authorization_policy.cos_flowlogs]
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v5.3.1"
  bucket_name              = "${local.prefix}-backend-flowlogs-bucket"
  create_cos_instance      = false
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  encryption_enabled       = false
  existing_cos_instance_id = (var.existing_cos_instance != "" ? data.ibm_resource_instance.cos.0.id : module.cos.0.cos_instance_id)
}

module "frontend_bucket" {
  depends_on               = [ibm_iam_authorization_policy.cos_flowlogs]
  source                   = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v5.3.1"
  bucket_name              = "${local.prefix}-frontend-flowlogs-bucket"
  create_cos_instance      = false
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  encryption_enabled       = false
  existing_cos_instance_id = (var.existing_cos_instance != "" ? data.ibm_resource_instance.cos.0.id : module.cos.0.cos_instance_id)
}

resource "ibm_is_flow_log" "frontend_collector" {
  depends_on     = [module.frontend_bucket]
  name           = "${local.prefix}-frontend-subnet-collector"
  target         = module.vpc.subnet_ids[0]
  active         = true
  storage_bucket = module.frontend_bucket.bucket_name[0]
}

resource "ibm_is_flow_log" "backend_collector" {
  depends_on     = [module.backend_bucket]
  name           = "${local.prefix}-backend-subnet-collector"
  target         = module.backend_subnet.subnet_id
  active         = true
  storage_bucket = module.backend_bucket.bucket_name[0]
}

module "ansible" {
  depends_on = [
    ibm_is_instance.cluster
  ]
  source      = "./ansible"
  instances   = ibm_is_instance.cluster[*]
  bastion_ip  = ibm_is_floating_ip.bastion.address
  region      = var.region
  encrypt_key = var.encryption_key
}

